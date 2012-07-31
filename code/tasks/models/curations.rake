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
    puts "Type 'archives' to see the archived curations for this researcher"
    puts "Type 'archive curation_id' to archive a curation"
    puts "Type 'unarchive curation_id' to reactivate a curation"
    puts "Type 'finish' at any time to go up one level in management" 
    puts "Type 'exit' at any time to boot out" 
    answer = Sh::clean_gets
    while answer!="finish"
      if answer[0..2] == "man"
        curation = Curation.first(:id => answer.gsub("man ", ""))
        puts "Curation not found!" if curation.nil?
        if !curation.nil?
          puts "From here, you can do all sorts of stuff:"
          puts "Type 'list' to see current stats about this curation"
          puts "Type 'analyze' to select analysis processes for the curation"
          puts "Type 'remove function_name' to clear an analysis process for the curation"
          puts "Type 'clear' to clear all analysis processes for the curation"
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
            elsif answer == "analyze"
              select_analysis_metadata(curation)
            elsif answer[0..6] == "remove "
              remove_analysis_metadata(answer, curation)
            elsif answer == "clear"
              curation.analysis_metadatas.each do |am|
                am.clear
              end
            end
            answer = Sh::clean_gets
          end
        end
      elsif answer=="archives"
        curations = Curation.all_deleted(:researcher_id => researcher.id)
        if curations.blank?
          puts "#{researcher.user_name}'s archive is empty."
        else
          curations.each do |curation|
            puts "ID: #{curation.id} Name: #{curation.name} Date Created: #{curation.created_at} Number of Datasets: #{curation.datasets.length}"
          end
          puts "Note: you must unarchive a curation in order to manage it."
        end
      elsif answer[0..6]=="archive"
        puts "Archiving Curation.."
        curation = Curation.first(:id => answer.gsub("archive ", ""))
        if curation
          if curation.researcher == researcher
            curation.archived = true
            curation.save
            puts "Curation successfully archived!"
          else
            puts "You can't archive a curation you do not own!"
          end
        else
          puts "Curation not found. Try again."
        end
      elsif answer[0..8]=="unarchive"
        puts "Unarchiving Curation.."
        curation = Curation.first_deleted(:id => answer.gsub("unarchive ", ""))
        if curation
          if curation.researcher == researcher
            curation.archived = false
            curation.save
            puts "Curation successfully unarchived!"
          else
            puts "You can't unarchive a curation you do not own!"
          end
        else
          puts "Curation not found. Try again."
        end
      else
        puts "Sorry, I didn't understand your entry. Try again?"
        answer = Sh::clean_gets
      end
      puts "Type 'man curation_id' to see more information about a curation"
      puts "Type 'archives' to see the archived curations for this researcher"
      puts "Type 'archive curation_id' to archive a curation"
      puts "Type 'unarchive curation_id' to reactivate a curation"
      puts "Type 'finish' at any time to boot out of management"
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
