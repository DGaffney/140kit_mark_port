namespace :curation do
  desc "Create a new curation."
  task :new => :environment do
    researcher = load_researcher
    puts "What type of curation will this be? (Can choose from: #{Dataset.scrape_types.inspect})"
    answer = Sh::clean_gets
    while !Dataset.scrape_types.include?(answer)
      puts "Sorry, that wasn't one of the options. Type the exact name please."
      answer = Sh::clean_gets
    end
    dataset = Dataset.new
    dataset.scrape_type = answer
    clean_params = validate_params(answer)
    params = {}
    params[:geocoded] = true if clean_params[:geocoded]
    params[:matches_some_terms] = clean_params[:matches_some_terms] if !clean_params[:matches_some_terms].empty?
    params[:matches_all_terms] = clean_params[:matches_all_terms] if !clean_params[:matches_all_terms].empty?
    params[:regions] = clean_params[:regions] if !clean_params[:regions].empty?
    params[:clean_params] = clean_params[:clean_params]
    params[:needs_counting] = clean_params[:needs_counting]
    if dataset.scrape_type != "import" && dataset.scrape_type != "audience_profile"
      puts "How long would you like to have this collection run? (Enter in number of seconds. I know, that's annoying. Enter -1 for indefinite (you can always kill the scrape later.))"
      answer = Sh::clean_gets
      while answer.to_i==0
        puts "Sorry, we couldn't parse that value. Just numbers, please, you know, like '300'."
        answer = Sh::clean_gets
      end
      params[:time] = answer.to_i
    elsif dataset.scrape_type == "import"
      dataset.created_at = clean_params[:start_time]
      params[:time] = clean_params[:end_time]-clean_params[:start_time]
    end
    dataset.params = params
    dataset.save!
    curation = create_curation(dataset, researcher)
    select_analysis_metadata(curation)
  end

  desc "Manage existing Curations"
  task :manage => :environment do
    puts "First, I'll need to get the name of the researcher whose curations you want to manage:"
    researcher = load_researcher
    puts "Researcher #{researcher.user_name} has #{researcher.curations.length} active curations."
    researcher.curations.each do |curation|
      puts "ID: #{curation.id} Name: #{curation.name} Date Created: #{curation.created_at} Number of Datasets: #{curation.datasets.length}"
    end
    manage_curations(researcher)
  end
  
  def manage_curations(researcher)
    puts "Type 'man curation_id' to see more information about a curation"
    puts "Type 'exit' at any time to boot out" 
    answer = Sh::clean_gets
    while answer!="finish"
      if answer[0..2] == "man"
        curation = Curation.first(:id => answer.gsub("man ", ""))
        puts "Curation not found!" if curation.nil?
        if !curation.nil?
          puts "From here, you can do all sorts of stuff:"
          puts "Type 'list' to see current stats about this curation"
          puts "Type 'export' to export records and models from this curation"
          puts "Type 'drop' to remove this dataset entirely from the service."
          puts "Type 'finish' to exit the curation and return to management."
          answer = Sh::clean_gets
          while answer!="finish"
            if answer == "list"
              puts "Curation Stats:"
              puts "Tweets: #{curation.tweets_count}"
              puts "Users: #{curation.users_count}"
              puts "Total Analytical Processes: #{curation.analysis_metadatas.count}"
              curation.analysis_metadatas.each do |am|
                puts am.display_terminal
              end
            elsif answer == "export"
              export_curation(curation)
            elsif answer == "drop"
              drop_curation(curation)
            end
            answer = Sh::clean_gets
          end
        end
      else
        puts "Sorry, I didn't understand your entry. Try again?"
        answer = Sh::clean_gets
      end
      puts "Type 'man curation_id' to see more information about a curation"
      puts "Type 'exit' at any time to boot out" 
      answer = Sh::clean_gets
    end
  end
  
  def create_curation(dataset, researcher)
    name = dataset.params
    answer = Sh::clean_gets_yes_no("Currently, the curation will be named: #{dataset.params}. Change this?", "Sorry, one more time:")
    if answer
      puts "Enter name:"
      name = Sh::clean_gets
      answer = Sh::clean_gets_yes_no("Currently, the curation will be named: #{name}. Change this?", "Sorry, one more time:")
      while answer
        answer = Sh::clean_gets_yes_no("Currently, the curation will be named: #{name}. Change this?", "Sorry, one more time:")
        puts "Enter name:"
        name = Sh::clean_gets
      end
    end
    curation = Curation.new
    curation.name = name
    curation.researcher_id = researcher.id
    curation.datasets << dataset
    curation.save
    curation
  end
  
  def export_curation(curation)
    puts "Alright, would you like mysql dumps of the data or TSVs? (type 'mysql' or 'tsv')"
    data_export_type = Sh::clean_gets
    while !["tsv", "mysql"].include?(data_export_type)
      fix = Sh::clean_gets_yes_no("Hrm, I didn't understand.", "One more time:")
      data_export_type = Sh::clean_gets
    end
    puts "What models are you interested in looking at? You can enter any of the following models: 'tweets','users','entities','geos','coordinates'"
    set = []
    real_models = ["tweets","users","entities","geos","coordinates"]
    models = Sh::clean_gets.gsub("'","").split(",")
    set = set+(models&real_models)
    answer = Sh::clean_gets_yes_no("So far, you've specified #{set.join(", ")}. Add more?", "Sorry, one more time:")
    while set.length < 5 && !answer
      models = Sh::clean_gets.gsub("'","").split(",")
      set = set+(models&real_models)
      answer = Sh::clean_gets_yes_no("So far, you've specified #{set.join(", ")}. Add more?", "Sorry, one more time:")
    end
    answer = Sh::clean_gets_yes_no("Last question: where do you want the results stored? This will be a relative path - right now, it will just be dumped in #{`pwd`}/exports. Want to change that at all?", "Sorry, one more time:")
    additional_path = ""
    if answer
      puts "Alright, change it to what?"
      answer = false
      while !answer
        additional_path = Sh::clean_gets
        answer = Sh::clean_gets_yes_no("We got #{additional_path.inspect}. Look right?", "Sorry, one more time:")        
      end
    end
    if data_export_type == "tsv"
      export_tsv(curation, set, additional_path)
    else
      export_mysql(curation, set, additional_path)      
    end
  end

  def drop_curation(curation)
    answer_count = 0
    while answer_count < 2
      answer = Sh::clean_gets_yes_no("Are you serious? Really? Sure you want to delete ALL the data without saving?")
      answer_count+=1 if answer
    end
    puts "Alllllllright.... I'm deleting now..."
    [Tweet,User,Entity,Geo,Coordinate].each do |model|
      DataMapper.repository.adapter.execute("delete from #{model.storage_name} where dataset_id in (#{curation.datasets.collect(&:id).join(",")})")
    end
    DataMapper.repository.adapter.execute("delete from #{Dataset.storage_name} where id in (#{curation.datasets.collect(&:id).join(",")})")
    DataMapper.repository.adapter.execute("delete from #{Curation.storage_name} where id in (#{curation.id})")
    puts "Well, I did it. It's gone."
  end

  def export_tsv(curation, set, additional_path="")
    config = DataMapper.repository.adapter.options
    curation.datasets.each do |dataset|
      set.each do |model|
        model = model.classify.constantize
        offset = 0
        limit = 10000
        finished = false
        remaining = model.count(:dataset_id => dataset.id)
        while !finished
          next_set = remaining>limit ? limit : remaining
          remaining = (remaining-limit)>0 ? remaining-limit : 0
          puts "Archiving #{offset} - #{offset+next_set} (#{model})"
          path = `pwd`.split("\n").first+"/exports/"+additional_path+"/"+model.to_s
          Sh::mkdir(path)
          filename = "curation_#{curation.id}_dataset_#{dataset.id}_#{offset}_#{offset+next_set}"
          mysql_section = "mysql -u #{config["user"]} --password='#{config["password"]}' -P #{config["port"]} -h #{config["host"]} #{config["path"].gsub("/", "")} -B -e "
          mysql_statement = "\"select * from #{model.storage_name} where dataset_id = #{dataset.id} limit #{limit};\""
          file_push = " | sed -n -e 's/^\"//;s/\"$//;s/\",\"/ /;s/\",\"/\\n/;P' > #{path}/#{filename}.tsv"
          command = "#{mysql_section}#{mysql_statement}#{file_push}"
          Sh::sh(command)
          Sh::compress(path+filename+".tsv")
          Sh::rm(path+filename+".tsv")
          offset += limit
          finished = true if remaining == 0
        end
      end
    end
  end
  
  def export_mysql(curation, set, additional_path="")
    config = DataMapper.repository.adapter.options
    curation.datasets.each do |dataset|
      set.each do |model|
        model = model.classify.constantize
        offset = 0
        limit = 10000
        finished = false
        remaining = model.count(:dataset_id => dataset.id)
        while !finished
          next_set = remaining>limit ? limit : remaining
          remaining = (remaining-limit)>0 ? remaining-limit : 0
          puts "Archiving #{offset} - #{offset+next_set} (#{model})"
          path = `pwd`.split("\n").first+"/exports/"+additional_path
          Sh::mkdir(path)
          filename = "curation_#{curation.id}_dataset_#{dataset.id}_#{offset}_#{offset+next_set}"
          command = "mysqldump -h #{db["host"]} -u #{db["username"]} -w \"dataset_id = #{dataset.id}\" --password=#{db["password"]} #{db["database"]} #{model.storage_name} > #{path}#{filename}.sql"
          Sh::sh(command)
          Sh::compress(path+filename+".sql")
          Sh::rm(path+filename+".sql")
          offset += limit
          finished = true if remaining == 0
        end
      end
    end
  end

  def validate_params(scrape_type)
    response = {}
    case scrape_type
    when "track"
      puts "A track scrape will track and collect all Tweets (and Users), from now until when you specify, for a given word or phrase.\n Enter phrase now:"
      answer = Sh::clean_gets
      response = Dataset.valid_params("track", answer)
      while !response[:reason].empty?
        puts "Sorry, that was not valid input. Reason: #{response[:reason]}"
        answer = Sh::clean_gets
        response = Dataset.valid_params("track", answer)
      end
    when "follow"
      puts "A follow scrape will follow and collect all Tweets from a given set of users (screen names only), from now until when you specify.\n Enter users, delimited by commas, now:"
      answer = Sh::clean_gets
      response = Dataset.valid_params("follow", answer)
      while !response[:reason].empty?
        puts "Sorry, that was not valid input. Reason: #{response[:reason]}"
        answer = Sh::clean_gets
        response = Dataset.valid_params("follow", answer)
      end
    when "locations"
      puts "A locations scrape will track and collect all Tweets (and Users), from now until when you specify, for a\n given geographic area entered like: -74,40,-73,41 (A one-degree square\n from -74 and 40 to -73 and 41. Decimals are acceptable to any accuracy).\n Enter location boundings now:"
      answer = Sh::clean_gets
      response = Dataset.valid_params("locations", answer)
      while !response[:reason].empty?
        puts "Sorry, that was not valid input. Reason: #{response[:reason]}"
        answer = Sh::clean_gets
        response = Dataset.valid_params("locations", answer)
      end
    when "sample"
      puts "You don't have to input params for a random sample - skipping parameter setting"
      response = {:clean_params => " "}
    when "import"
      puts "What time range are you interested in? To enter this, please enter times like this: #{(Time.now-3600*24*5).strftime("%Y-%m-%d %H:%M:%S")} to #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      finalized = false
      start_time = nil
      end_time = nil
      while !finalized
        answer = Sh::clean_gets
        start_time = Time.parse(answer.split(" to ").first) rescue nil
        end_time = Time.parse(answer.split(" to ").last) rescue nil
        while start_time.nil? || end_time.nil?
          puts "Sorry, we didn't correctly interpret your time range. Please try again:"
          answer = Sh::clean_gets
          start_time = Time.parse(answer.split(" to ").first) rescue nil
          end_time = Time.parse(answer.split(" to ").last) rescue nil
        end
        finalized = Sh::clean_gets_yes_no("We got #{start_time.strftime("%Y-%m-%d %H:%M:%S")} to #{end_time.strftime("%Y-%m-%d %H:%M:%S")}. Is that correct?", "Sorry, one more time:")
      end
      answer = Sh::clean_gets_yes_no("Are there any datasets you wish to exclude? Enter the ID's, separated by commas (You can also look at existing datasets by running rake curation:manage)", "Sorry, one more time:")
      ids = []
      if answer
        ids_correct = false
        while !ids_correct
          puts "Enter them now:"
          id_raw= Sh::clean_gets.split(",")
          ids = Dataset.all(:fields => [:id], :id => id_raw).collect(&:id)
          ids_correct = Sh::clean_gets_yes_no("We got #{ids.inspect}. Sound right?", "Sorry, one more time:")
        end
      end
      response = {:clean_params => " ", :start_time => start_time, :end_time => end_time}
      response[:exclude_ids] = ids if !ids.empty?
    end
    puts "Alright, so here's the advanced settings:"
    answer = Sh::clean_gets_yes_no("Do you only want to collected geocoded data?", "Sorry, one more time:")
    response[:geocoded] = answer
    puts "The next two of these are case-sensitive matches - be aware of that..."
    answer = Sh::clean_gets_yes_no("Are there any terms that you would like to match on? In this case, we'll accept tweets that match any single term.", "Sorry, one more time:")
    terms = []
    if answer
      answer = true
      while answer
        puts "What is the term?"
        this_answer = false
        term = ""
        while !this_answer
          term = Sh::clean_gets
          this_answer = Sh::clean_gets_yes_no("We got '#{term}'. Is this right?", "Sorry, one more time:")
          puts "What is the term?" if !this_answer
        end
        terms << term
        answer = Sh::clean_gets_yes_no("Any more terms?.", "Sorry, one more time:")
      end
    end
    response[:matches_some_terms] = terms if !terms.empty?
    answer = Sh::clean_gets_yes_no("Are there any terms that you would like to match on? In this case, we'll accept tweets that match every single term.", "Sorry, one more time:")
    terms = []
    if answer
      answer = true
      while answer
        puts "What is the term?"
        this_answer = false
        term = ""
        while !this_answer
          term = Sh::clean_gets
          this_answer = Sh::clean_gets_yes_no("We got '#{term}'. Is this right?", "Sorry, one more time:")
          puts "What is the term?" if !this_answer
        end
        terms << term
        answer = Sh::clean_gets_yes_no("Any more terms?.", "Sorry, one more time:")
      end
    end
    response[:matches_all_terms] = terms if !terms.empty?
    answer = Sh::clean_gets_yes_no("Do you want tweets to come from specific sub regions? (Write these the same way as you would any other bounding box.)", "Sorry, one more time:")
    geocodes = []
    if answer
      answer = true
      while answer
        puts "What is the region?"
        this_answer = false
        geocode = ""
        while !this_answer
          response[:reason] = ""
          geocode = Sh::clean_gets
          location_response = Dataset.valid_params("locations", geocode)
          while !location_response[:reason].empty?
            puts "Sorry, that was not valid input. Reason: #{location_response[:reason]}"
            geocode = Sh::clean_gets
            location_response = Dataset.valid_params("locations", geocode)
          end
          this_answer = Sh::clean_gets_yes_no("We got '#{geocode}'. Is this right?", "Sorry, one more time:")
          puts "What is the region?" if !this_answer
        end
        geocodes << geocode
        answer = Sh::clean_gets_yes_no("Any more regions?.", "Sorry, one more time:")
      end
    end
    response[:regions] = geocodes if !geocodes.empty?
    answer = Sh::clean_gets_yes_no("Do you need to know how many tweets are missed? (NOTE: This will only allow one search per account, so the resources for this type of search are limited.)", "Sorry, one more time:")
    response[:needs_counting] = answer
    return response
  end
end
