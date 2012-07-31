load File.dirname(__FILE__)+'/../environment.rb'
class Filter < Instance

  MAX_TRACK_IDS = 10000
  BATCH_SIZE = 100
  STREAM_API_URL = "http://stream.twitter.com"
  CHECK_FOR_NEW_DATASETS_INTERVAL = 60*10
  attr_accessor :user_account, :username, :password, :next_dataset_ends, :queue, :params, :datasets, :start_time, :last_start_time, :scrape_type, :graph_point, :skipped_this_round, :skipped_last_round, :count

  def initialize
    super
    @datasets = []
    @queue = []
    @count = 0
    @graph_point = GraphPoint.first_or_create(:analysis_metadata_id => 0, :label => "skip_count_gaff", :graph_id => 0, :curation_id => 0)
    @skipped_this_round = 0
    @skipped_last_round = 0
#    oauth_settings = YAML.load(File.read(File.dirname(__FILE__)+'/../config/twitter.yml'))
 #   account = oauth_settings.keys.shuffle.first
#    TweetStream.configure do |config|
#      config.consumer_key = "RBY3pMQVAYbHW3Eld1DUg" #oauth_settings[account]["oauth_settings"]["consumer_key"]
#      config.consumer_secret = "SyaJ6osRIQb3O4vsKsnNJoI31tWAhBYhgCQYS04"#oauth_settings[account]["oauth_settings"]["consumer_secret"]
#      config.oauth_token = "148584489-WtUwDdPvm9KGBk0TMDiZnTwqdgQdBPQ1fjHHnWCb"#oauth_settings[account]["access_token"]["access_token"]
#      config.oauth_token_secret = "mzHKf5IlByrTbItm8eb0tbyG1IQz6HzAO0E2MzMWgE"#oauth_settings[account]["access_token"]["access_token_secret"]
#      config.auth_method = :oauth
#      config.parser   = :yajl
#    end
    @start_time = Time.now
    @scrape_type = ARGV[0] || "track"
    at_exit { do_at_exit }
  end
  
  def do_at_exit
    puts "Exiting."
    save_queue
    @user_account.unlock
    @datasets.collect{|dataset| dataset.unlock}
  end
  
  def filt
    puts "Filtering..."
    check_in
    assign_user_account
    puts "Entering filter routine."
    loop do
      if !killed?
        stream_routine
      else
        puts "Just nappin'."
        sleep(SLEEP_CONSTANT)
      end
    end
  end
  
  def stream_routine
    add_datasets
    clean_up_datasets
    if !@datasets.empty?
      update_next_dataset_ends
      update_params
      collect
      save_queue_2
      clean_up_datasets
    end
  end
  
  def assign_user_account
    puts "Assigning user account."
    message = true
    while @screen_name.nil?
      user = AuthUser.unlocked.first
      if !user.nil? && user.lock
        @user_account = user
        @screen_name = user.screen_name
        @password = user.password
        puts "Assigned #{@screen_name}."
      else
        answer = Sh::clean_gets_yes_no("No twitter accounts available. Add one now?") if message
        if answer
          first_attempt = true
          while answer!="y" || first_attempt
            first_attempt = false
            puts "Enter your screen name:"
            screen_name = Sh::clean_gets
            puts "Enter your password:"
            password = Sh::clean_gets
            puts "We got the username '#{screen_name}' and a password that was #{password.length} characters long. Sound right-ish? (y/n)"
            answer = Sh::clean_gets
          end
          puts "Creating new AuthUser..."
          user = AuthUser.new(:screen_name => screen_name, :password => password)
          user.save
          user = AuthUser.unlocked.first
          @user_account = user
          @screen_name = user.screen_name
          @password = user.password
          puts "Assigned #{@screen_name}."
        else
          puts "Then I can't do anything for you. May god have mercy on your data"
          exit!
        end
        message = false
      end
      sleep(5)
    end
  end
  
  def collect
    @skipped_this_round = 0
    puts "Collecting: #{params_for_stream.inspect}"
    begin
      client = TweetStream::Client.new#(:username => '140kit', :password => 'bototo')
      TweetStream.configure do |config|
        config.consumer_key = "zOXQ1JhQjmrgQZtY2k60uw" #oauth_settings[account]["oauth_settings"]["consumer_key"]
        config.consumer_secret = "qtECkYcBrFf1NuCoL8Nq0CyxyFy2QfjcpkW9ZuKqWY" #oauth_settings[account]["oauth_settings"]["consumer_secret"]
        config.oauth_token = "13731562-mmI3rOLgR8pCzcuklgFKAPgpGOVh3JAmIUlNqZM4M" #oauth_settings[account]["access_token"]["access_token"]
        config.oauth_token_secret = "AZmqNurBqygMkqywkweyUO5TA9u2frsufHXAyE7zJgc" #oauth_settings[account]["access_token"]["access_token_secret"]
        config.auth_method = :oauth
        config.parser   = :yajl
      end
      client.on_interval(CHECK_FOR_NEW_DATASETS_INTERVAL) { rsync_previous_files; @start_time = Time.now; puts "Switching to new files..."; client.stop if add_datasets }
      client.on_limit { |skip_count| determine_if_save_graph_point(skip_count); puts "\nWe are being rate limited! We lost #{skip_count} tweets!"}
      client.on_error { |message| puts "\nError: #{message}\n";client.stop }
      client.filter(params_for_stream) do |tweet|
        # puts "[tweet] #{tweet[:user][:screen_name]}: #{tweet[:text]}"
        @queue << tweet
        save_queue_2 #if @queue.length >= BATCH_SIZE
        if @next_dataset_ends
          client.stop if U.times_up?(@next_dataset_ends)
        end
      end
    save_queue_2
    rescue
      retry
    end
  end

  def determine_if_save_graph_point(skip_count)
    @skipped_last_round = @skipped_this_round
    @skipped_this_round = skip_count.to_i
    if @skipped_last_round >= @skipped_this_round
      puts @skipped_this_round
      puts @graph_point.attributes
      @graph_point.value = 0 if @graph_point.value.nil?
      value = (@graph_point.value.to_i+@skipped_last_round.to_i).to_s
      @graph_point.value = value
      @graph_point.save!      
    end
  end

  def params_for_stream
    params = {}
    @params.each {|k,v| params[k.to_sym] = v.collect {|x| x[:params] } }
    return params
  end
  
  def save_queue
    Thread.new do
    if !@queue.empty?
      puts "Saving #{@queue.length} tweets."
      tweets, users, entities, geos, coordinates = data_from_queue
      @queue = []
      Thread.new {
        dataset_ids = tweets.collect{|t| t[:dataset_id]}.uniq
        dataset_ids.each do |dataset_id|
          Tweet.store_to_flat_file(tweets.select{|t| t[:dataset_id] == dataset_id}, dir(Tweet, dataset_id))
          User.store_to_flat_file(users.select{|u| u[:dataset_id] == dataset_id}, dir(User, dataset_id))
          Entity.store_to_flat_file(entities.select{|e| e[:dataset_id] == dataset_id}, dir(Entity, dataset_id))
          Geo.store_to_flat_file(geos.select{|g| g[:dataset_id] == dataset_id}, dir(Geo, dataset_id))
          Coordinate.store_to_flat_file(coordinates.select{|c| c[:dataset_id] == dataset_id}, dir(Coordinate, dataset_id))
#          tweet_ids = tweets.collect{|x| x[:twitter_id] if !x[:lat].nil?}.compact
#          user_ids = tweets.select{|x| tweet_ids.include?(x[:twitter_id])}.collect{|x| x[:user_id]}.compact
#	  Tweet.save_all(tweets.select{|t| t[:dataset_id] == dataset_id}.select{|x| tweet_ids.include?(x[:twitter_id])})
#	  User.save_all(users.select{|u| u[:dataset_id] == dataset_id}.select{|x| user_ids.include?(x[:twitter_id])})
#	  Entity.save_all(entities.select{|e| e[:dataset_id] == dataset_id}.select{|x| tweet_ids.include?(x[:twitter_id])})
#	  Geo.save_all(geos.select{|g| g[:dataset_id] == dataset_id}.select{|x| tweet_ids.include?(x[:twitter_id])})
#	  Coordinate.save_all(coordinates.select{|c| c[:dataset_id] == dataset_id}.select{|x| tweet_ids.include?(x[:twitter_id])})
        end
      }
    end
    end
  end
  def save_queue_2
    t = Time.now
    dataset_id = 137
    tweets, users, entities, geos, coordinates = data_from_queue
    Tweet.store_to_flat_file(tweets.select{|t| t[:dataset_id] == dataset_id}, dir(Tweet, dataset_id))
    User.store_to_flat_file(users.select{|u| u[:dataset_id] == dataset_id}, dir(User, dataset_id))
    Entity.store_to_flat_file(entities.select{|e| e[:dataset_id] == dataset_id}, dir(Entity, dataset_id))
    Geo.store_to_flat_file(geos.select{|g| g[:dataset_id] == dataset_id}, dir(Geo, dataset_id))
    Coordinate.store_to_flat_file(coordinates.select{|c| c[:dataset_id] == dataset_id}, dir(Coordinate, dataset_id))
    @count+=1
    @queue = []
    tt = Time.now-t
    puts "Saved total of #{@count} (#{tt})"
  end

  
  def dir(model, dataset_id)
    return "#{ENV["TMP_PATH"]}/#{model}/#{dataset_id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}"
  end
  
  def rsync_previous_files
#    rsync_job = fork do
      [Tweet, User, Entity, Geo, Coordinate].each do |model|
        @datasets.each do |dataset|
          Sh::mkdir("#{STORAGE["path"]}/#{model}")
          store_to_disk("#{dir(model, dataset.id)}.tsv", "#{model}/#{dataset.id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}.tsv")
#          `rm #{dir(model, dataset.id)}.tsv`
        end
      end
 #   end
  #  Process.detach(rsync_job)
  end

  def data_from_queue
    tweets = []
    users = []
    entities = []
    geos = []
    coordinates = []
    @queue.each do |json|
      tweet, user = TweetHelper.prepped_tweet_and_user(json)
      geo = GeoHelper.prepped_geo(json)
      dataset_ids = determine_datasets(json)
      tweets      = tweets+dataset_ids.collect{|dataset_id| tweet.merge({:dataset_id => dataset_id})}
      users       = users+dataset_ids.collect{|dataset_id| user.merge({:dataset_id => dataset_id})}
      geos        = geos+dataset_ids.collect{|dataset_id| geo.merge({:dataset_id => dataset_id})}
      coordinates = coordinates+CoordinateHelper.prepped_coordinates(json).collect{|coordinate| dataset_ids.collect{|dataset_id| coordinate.merge({:dataset_id => dataset_id})}}.flatten
      entities    = entities+EntityHelper.prepped_entities(json).collect{|entity| dataset_ids.collect{|dataset_id| entity.merge({:dataset_id => dataset_id})}}.flatten
    end
    return tweets, users, entities, geos, coordinates
  end
  
  def update_params
    @params = {}
    for d in @datasets
      if @params[d.scrape_type]
        if d.scrape_type == "locations"
          @params[d.scrape_type] << {:params => d.params.split(",")[0..d.params.split(",").length-2].join(","), :dataset_id => d.id}
        else
          @params[d.scrape_type] << {:params => d.params.split(",").first, :dataset_id => d.id}
        end
      else
        if d.scrape_type == "locations"
          @params[d.scrape_type] = [{:params => d.params.split(",")[0..d.params.split(",").length-2].join(","), :dataset_id => d.id}]
        else
          @params[d.scrape_type] = [{:params => d.params.split(",").first, :dataset_id => d.id}]
        end
      end
    end
  end
  
  def determine_datasets(tweet)
    return [@datasets.first.id] if @datasets.length == 1
    valid_datasets = []
    params.each_pair do |method, values|
      if method == "locations"
        values.each do |value|
          valid_datasets << value[:dataset_id] if any_in_location?(value[:params], tweet)
        end
      elsif method == "track"
        values.each do |value|
          if value[:params].include?(" ")
            valid_datasets << value[:dataset_id] if tweet[:text].include?(value[:params]) #add .downcase to set case sensitivity off...
          else
            valid_datasets << value[:dataset_id] if tweet[:text].split(/[~!$%^&* \[\]\(\)\{\}\-=_+.,\/<>?:;"']/).include?(value[:params])
          end
        end
      elsif method == "follow"
        values.each do |value|
          valid_datasets << value[:dataset_id] if tweet[:user][:id] == value[:params].to_i
        end
      end
    end
    return valid_datasets
  end
  
  def any_in_location?(location, tweet)
    coords = CoordinateHelper.prepped_coordinates(tweet)
    found = false
    coords.each do |coord|
      found = true if in_location?(location, coord[:lat], coord[:lon])
      break if found
    end
    return found
  end

  def in_location?(location_params, lat, lon)
    search_location = location_params.split(",").map {|c| c.to_i }
    l_lon_range = (search_location[0]..search_location[2])
    l_lat_range = (search_location[1]..search_location[3])
    return (l_lon_range.include?(lon) && l_lat_range.include?(lat))
  end
  
  # def in_bounding_box?(location_params)
  #   t = self[:place][:bounding_box][:coordinates].first
  #   s = location_params.split(",").map {|c| c.to_f }
  #   a = { :left => t[0][0],
  #         :bottom => t[0][1],
  #         :right => t[2][0],
  #         :top => t[2][1] }
  #   b = { :left => s[0],
  #         :bottom => s[1],
  #         :right => s[2],
  #         :top => s[3] }
  #   abxdif = ((a[:left]+a[:right])-(b[:left]+b[:right])).abs
  #   abydif = ((a[:top]+a[:bottom])-(b[:top]+b[:bottom])).abs
  #   xdif = (a[:right]+b[:right])-(a[:left]+b[:left])
  #   ydif = (a[:top]+b[:top])-(a[:bottom]+b[:bottom])
  #   return (abxdif <= xdif && abydif <= ydif)
  # end
  
  def add_datasets
    datasets = Dataset.unlocked.all(:scrape_finished => false, :scrape_type => @scrape_type)
    return claim_new_datasets(datasets)
  end

  def claim_new_datasets(datasets)
    # distribute datasets evenly
    return false if datasets.empty?
    num_instances = Instance.count(:instance_type => "streamer", :killed => false)
    datasets_per_instance = num_instances.zero? ? datasets.length : (datasets.length.to_f / num_instances.to_f).ceil
    datasets_to_claim = datasets[0..datasets_per_instance]
    if !datasets_to_claim.empty?
     claimed_datasets = Dataset.lock(datasets_to_claim)
     if !claimed_datasets.empty?
       update_datasets(claimed_datasets)
       return true
     end
    end
    return false
  end
   
  def update_datasets(datasets)
    @datasets = @datasets|datasets
    if @datasets.length > MAX_TRACK_IDS
      denied_datasets = []
      @datasets -= (denied_datasets = @datasets[MAX_TRACK_IDS-1..datasets.length])
      unlock(denied_datasets)
    end
  end

  def update_next_dataset_ends
    update_start_times
    refresh_datasets # this is absolutely necessary even while it's called in update_start_times above. huh!
    soonest_ending_dataset = @datasets.select{|d| d.params.split(",").last.to_i!=-1}.sort {|x,y| (x.created_at.to_time.gmt + x.params.split(",").last.to_i - DateTime.now.to_time.gmt) <=> (y.created_at.to_time.gmt + y.params.split(",").last.to_i - DateTime.now.to_time.gmt) }.first
    @next_dataset_ends = soonest_ending_dataset.created_at.to_time.gmt + soonest_ending_dataset.params.split(",").last.to_i rescue nil
  end

  def update_start_times
    refresh_datasets
    datasets_to_be_started = @datasets.select {|d| d.created_at.nil? }
    # Dataset.update_all({:created_at => DateTime.now.in_time_zone}, {:id => datasets_to_be_started.collect {|d| d.id}})
    Dataset.all(:id => datasets_to_be_started.collect {|d| d.id}).update(:created_at => Time.now)
    refresh_datasets
  end

  def refresh_datasets
    @datasets = Dataset.all(:id => @datasets.collect {|d| d.id })
  end

  def clean_up_datasets
    started_datasets = @datasets.reject {|d| d.created_at.nil? }
    finished_datasets = started_datasets.select{|d| d.params.split(",").last.to_i!=-1}.select {|d| U.times_up?(d.created_at.gmt+d.params.split(",").last.to_i) }
    if !finished_datasets.empty?
      puts "Finished collecting "+finished_datasets.collect {|d| "#{d.scrape_type}:\"#{d.internal_params_label}\"" }.join(", ")
      # Dataset.update_all({:scrape_finished => true}, {:id => finished_datasets.collect {|d| d.id}})
      Dataset.all(:id => finished_datasets.collect {|d| d.id}).update(:scrape_finished => true)
      @datasets -= finished_datasets
      finished_datasets.collect{|dataset| dataset.unlock}
    end
  end
  
end

filter = Filter.new
filter.username = "140kit"
filter.filt

