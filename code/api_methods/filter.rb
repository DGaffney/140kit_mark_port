load File.dirname(__FILE__)+'/../environment.rb'
class Filter < Instance

  attr_accessor :screen_name, :password, :param_period, :last_params_update, :queue, :params, :datasets, :skipped_this_round, :skipped_last_round, :next_dataset_ends, :batch_size

  def initialize
    @screen_name = nil
    @password = nil
    @param_period = 600
    @batch_size = 100
    @last_params_update = Time.now-(@param_period+1)
    @params = {}
    @queue = []
    @datasets = []
    @skipped_this_round = 0
    @skipped_last_round = 0
    @next_dataset_ends = Time.now
    @valid_tweets_missed = 0
    @sorted_queue = {}
    super
    self.save
  end

  def filt
    loop do
      assign_user if @screen_name.nil? || @password.nil?
      collect_data
    end
  end
  
  def assign_user
    user = AuthUser.unlocked.first
    if user
      @screen_name = user.screen_name
      @password = user.password
      user.lock
    end
  end
  
  def collect_data
    collect_params
    return if @params[:scrape_type].nil?
    update_next_dataset_ends
    collect if !@datasets.empty?
    clean_up_datasets
  end

  def collect_params
    datasets = Dataset.unlocked.all(:scrape_finished => false, :scrape_type => ["track", "location", "follow", "sample"])
    datasets.each do |dataset|
      @params[:scrape_type] = dataset.scrape_type if @params[:scrape_type].nil?
      @params[:params] = [] if @params[:params].nil?
      @params[:params] << dataset.params.merge({:dataset_id => dataset.id}) if addable(dataset)
      @datasets << dataset if addable(dataset)
      @params[:needs_counting] = true if dataset.params[:needs_counting] == true
      dataset.lock if @datasets.include?(dataset)
    end
    sleep(2)
    @datasets.each do |dataset|
      @datasets=@datasets-[dataset] if !dataset.owned_by_me?
    end
  end
  
  def addable(dataset)
    dataset.scrape_type == @params[:scrape_type] &&
    !@datasets.collect{|x| x.params[:needs_counting]}.include?(true) && 
    (dataset.params[:needs_counting] == false || dataset.params[:needs_counting] == true && @datasets.empty?)
  end

  def collect
    puts "Collecting: #{params_for_stream.inspect}"
    TweetStream.configure do |config|
      config.username = @screen_name
      config.password = @password
      config.auth_method = :basic
      config.parser = :yajl
    end
    client = TweetStream::Client.new
    client.on_interval(@param_period) { puts "Switching to new files..."; client.stop if add_datasets }
    client.on_limit { |skip_count| update_skip_count(skip_count); puts "\nWe are being rate limited! We lost #{skip_count} tweets!\n" }
    client.on_error { |message| puts "\nError: #{message}\n"; client.stop }
    if ["track", "locations", "follow"].include?(@params[:scrape_type])
      client.filter(params_for_stream) do |tweet|
        begin
          print "."
          @queue << tweet
          select_and_tag_matching_tweets if @queue.length >= @batch_size
          if @next_dataset_ends
            client.stop if U.times_up?(@next_dataset_ends)
          end
        rescue
          select_and_tag_matching_tweets
          retry
        end
      end
      select_and_tag_matching_tweets
    elsif @params[:scrape_type] == "sample"
      client.sample do |tweet|
        begin
          print "."
          @queue << tweet
          select_and_tag_matching_tweets if @queue.length >= @batch_size
          if @next_dataset_ends
            client.stop if U.times_up?(@next_dataset_ends)
          end
        rescue
          select_and_tag_matching_tweets
          retry
        end
      end
      select_and_tag_matching_tweets
    elsif @params[:scrape_type] == "import"
      offset = 0
      limit = 1000
      useless_attrs = [:id,:dataset_id]
      attrs = Tweet.attributes-useless_attrs
      tweets = Tweet.all(:unique => true, :limit => limit, :offset => offset, :fields => attrs)
      while !tweets.empty?
        puts "Processing corpus of Twitter data for copy into new dataset..."
        users = User.all(:twitter_id => tweets.collect(&:user_id))
        entities = Entity.all(:twitter_id => tweets.collect(&:twitter_id))
        geos = Geo.all(:twitter_id => tweets.collect(&:twitter_id))
        coordinates = Coordinate.all(:twitter_id => tweets.collect(&:twitter_id))
        tweets.each do |tweet|
          user = users.collect{|u| Hashie::Mash[u.attributes] if u.twitter_id == tweet.user_id}.compact.first
          these_entities = entities.collect{|e| Hashie::Mash[e.attributes] if e.twitter_id == tweet.twitter_id}.compact
          geo = geos.collect{|g| Hashie::Mash[g.attributes] if g.twitter_id == tweet.twitter_id}.compact.first
          these_coordinates = coordinates.collect{|c| Hashie::Mash[c.attributes] if c.twitter_id == tweet.twitter_id}.compact
          @queue.each do |tweet|
            @params[:params].each do |d_params|
              match_tweet(tweet, d_params, user, these_geos, these_entities, these_coordinates)
            end
          end
          tweets = [];users = [];entities = [];coordinates = [];geos = []
          @sorted_queue.each_pair do |k,v|
            tweets = tweets|v[:tweets]
            users = users|v[:users]
            coordinates = coordinates|v[:coordinates]
            geos = geos|v[:geos]
            entities = entities|v[:entities]
          end
          Tweet.save_all(tweets)
          User.save_all(users)
          Entity.save_all(entities)
          Geo.save_all(geos)
          Coordinate.save_all(coordinates)
          @sorted_queue = {}
          @tmp_queue = {}
          @queue = []
        end
      end
    end
  end
  
  def params_for_stream
    {@params[:scrape_type] => @params[:params].collect{|p| p[:clean_params]}}
  end
  
  def update_skip_count(skip_count)
    if @params[:needs_counting]
      dataset = @datasets.first
      @skipped_last_round = @skipped_this_round
      @skipped_this_round = skip_count.to_i
      if @skipped_last_round >= @skipped_this_round
        dataset.tweets_missed = 0 if dataset.tweets_missed.nil?
        value = (dataset.tweets_missed.to_i+@skipped_last_round.to_i)
        dataset.tweets_missed = value
        dataset.tweets_missed.save!      
      end
    end
  end
  
  def select_and_tag_matching_tweets
    @queue.each do |tweet|
      @params[:params].each do |d_params|
        match_tweet(tweet, d_params)
      end
    end
    tweets = [];users = [];entities = [];coordinates = [];geos = []
    @sorted_queue.each_pair do |k,v|
      tweets = tweets|v[:tweets]
      users = users|v[:users]
      coordinates = coordinates|v[:coordinates]
      geos = geos|v[:geos]
      entities = entities|v[:entities]
    end
    Tweet.save_all(tweets)
    User.save_all(users)
    Entity.save_all(entities)
    Geo.save_all(geos)
    Coordinate.save_all(coordinates)
    @sorted_queue = {}
    @tmp_queue = {}
    @queue = []
  end
  
  def match_tweet(tweet, d_params, user=nil, geo=nil, entities=nil, coordinates=nil)
    @sorted_queue[d_params[:dataset_id]] = {} if @sorted_queue[d_params[:dataset_id]].nil?
    @sorted_queue[d_params[:dataset_id]][:tweets] = [] if @sorted_queue[d_params[:dataset_id]][:tweets].nil?||@sorted_queue[d_params[:dataset_id]][:tweets].empty?
    @sorted_queue[d_params[:dataset_id]][:geos] = [] if @sorted_queue[d_params[:dataset_id]][:geos].nil?||@sorted_queue[d_params[:dataset_id]][:geos].empty?
    @sorted_queue[d_params[:dataset_id]][:coordinates] = [] if @sorted_queue[d_params[:dataset_id]][:coordinates].nil?||@sorted_queue[d_params[:dataset_id]][:coordinates].empty?
    @sorted_queue[d_params[:dataset_id]][:users] = [] if @sorted_queue[d_params[:dataset_id]][:users].nil?||@sorted_queue[d_params[:dataset_id]][:users].empty?
    @sorted_queue[d_params[:dataset_id]][:entities] = [] if @sorted_queue[d_params[:dataset_id]][:entities].nil?||@sorted_queue[d_params[:dataset_id]][:entities].empty?
    primary_matches = false
    if user.nil?
      tweet,user,geo,entities,coordinates = parse_tweet(tweet)
    end
    primary_matches = primary_match(tweet, d_params)
    matches = {}
    matches[:geocoded] = ((d_params[:geocoded]==true && !tweet[:lat].nil? && !tweet[:lon].nil?) || d_params[:geocoded].nil?)
    matches[:matches_some_terms] = d_params[:matches_some_terms].nil? || matches_some_terms(tweet[:text], d_params)
    matches[:matches_all_terms] = d_params[:matches_all_terms].nil? || matches_all_terms(tweet[:text], d_params)
    matches[:regions] = d_params[:regions].nil? || within_bounds(tweet[:lat], tweet[:lon], d_params[:regions])
    if (matches.keys.length==matches.values.count(true)) && primary_matches
      tweet[:dataset_id] = d_params[:dataset_id]
      @sorted_queue[d_params[:dataset_id]][:tweets] << tweet
      user[:dataset_id] = d_params[:dataset_id]
      @sorted_queue[d_params[:dataset_id]][:users] << user
      @sorted_queue[d_params[:dataset_id]][:geos] = @sorted_queue[d_params[:dataset_id]][:geos]|[geo].reject(&:empty?).select{|g| g[:dataset_id] = d_params[:dataset_id]}
      @sorted_queue[d_params[:dataset_id]][:entities] = @sorted_queue[d_params[:dataset_id]][:entities]|entities.reject(&:empty?).select{|e| e[:dataset_id] = d_params[:dataset_id]}
      @sorted_queue[d_params[:dataset_id]][:coordinates] = @sorted_queue[d_params[:dataset_id]][:coordinates]|coordinates.reject(&:empty?).select{|c| c[:dataset_id] = d_params[:dataset_id]}
    else 
      @valid_tweets_missed+=1
    end
  end
  
  def primary_match(tweet, d_params)
    case @params[:scrape_type]
    when "track"
      return tweet[:text].include?(d_params[:clean_params])
    when "locations"
      return within_bounds(tweet[:lat], tweet[:lon], [d_params[:clean_params]])
    when "follow"
      return tweet[:screen_name] == d_params[:clean_params]
    when "sample"
      return true
    end
  end
  
  def parse_tweet(tweet)
    parsed_tweet = TweetHelper.prep_tweet(tweet)
    parsed_user = TweetHelper.prep_user(tweet.user)
    geos = GeoHelper.prepped_geo(tweet)
    entities = EntityHelper.prepped_entities(tweet)
    coordinates = CoordinateHelper.prepped_coordinates(tweet)
    return parsed_tweet,parsed_user,geos,entities,coordinates
  end
  
  def matches_some_terms(text, d_params)
    return true if d_params[:matches_some_terms].nil?
    matches = []
    d_params[:matches_some_terms].each do |term|
      matches << text.include?(term)
    end
    return matches.include?(true)
  end
  
  def matches_all_terms(text, d_params)
    return true if d_params[:matches_all_terms].nil?
    matches = []
    d_params[:matches_all_terms].each do |term|
      matches << text.include?(term)
    end
    return matches.uniq.length==1 && matches.uniq.first == true
  end
  
  def within_bounds(lat, lon, regions)
    debugger if !lat.nil?
    return true if regions.nil?
    matches_region = []
    regions.each do |region|
      region = region.split(",").collect(&:to_f)
      small_lon,large_lon = [region[0],region[2]].sort
      small_lat,large_lat = [region[1],region[3]].sort
      matches_region << ((small_lat..large_lat).include?(lat) && (small_lon..large_lon).include?(lon))
    end
    return matches_region.include?(true)
  end

  def update_next_dataset_ends
    update_start_times
    refresh_datasets # this is absolutely necessary even while it's called in update_start_times above. huh!
    soonest_ending_dataset = @datasets.select{|d| d.params[:time]!=-1}.sort {|x,y| (x.created_at.to_time.gmt + x.params[:time] - DateTime.now.to_time.gmt) <=> (y.created_at.to_time.gmt + y.params[:time] - DateTime.now.to_time.gmt) }.first
    @next_dataset_ends = soonest_ending_dataset.created_at.to_time.gmt + soonest_ending_dataset.params[:time] rescue nil
  end

  def update_start_times
    refresh_datasets
    datasets_to_be_started = @datasets.select {|d| d.created_at.nil? }
    Dataset.all(:id => datasets_to_be_started.collect {|d| d.id}).update(:created_at => Time.now)
    refresh_datasets
  end

  def refresh_datasets
    @datasets = Dataset.all(:id => @datasets.collect {|d| d.id })
  end

  def clean_up_datasets
    started_datasets = @datasets.reject {|d| d.created_at.nil? }
    finished_datasets = started_datasets.select{|d| d.params[:time]!=-1}.select {|d| U.times_up?(d.created_at+d.params[:time]) }
    if !finished_datasets.empty?
      puts "Finished collecting Datasets "+finished_datasets.collect {|d| "##{d.id}" }.join(", ")
      # Dataset.update_all({:scrape_finished => true}, {:id => finished_datasets.collect {|d| d.id}})
      Dataset.all(:id => finished_datasets.collect(&:id)).update(:scrape_finished => true)
      @datasets -= finished_datasets
      finished_datasets.each do |d|
        if @params[:needs_counting]
          d.tweets_missed = 0 if d.tweets_missed.nil?
          value = (d.tweets_missed.to_i+@skipped_last_round.to_i)
          d.tweets_missed = value
          d.valid_tweets_missed = (d.tweets_missed.to_i+@valid_tweets_missed.to_i)
          d.save!      
        end
        these_params = d.params
        these_params[:dataset_id] = d.id
        @params[:params]-=[these_params]
      end
      finished_datasets.collect{|dataset| dataset.unlock}
    end
  end
  
end

filter = Filter.new
filter.filt

