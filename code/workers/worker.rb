load File.dirname(__FILE__)+'/../environment.rb'
load File.dirname(__FILE__)+'/../analyzer/analysis.rb'
class Worker < Instance
  
  # attr_accessor :user_account, :username, :password, :start_time, :next_dataset_ends, :queue, :params, :datasets
  attr_accessor :curation
  
  @@words = File.open(File.dirname(__FILE__)+"/../analyzer/resources/words.txt", "r").read.split
  @@rest_analytics = ["retweet_graph"]
  
  def initialize
    super
    self.instance_type = "worker"
    self.save
    # @datasets = []
    # @queue = []
    at_exit { do_at_exit }
  end
  
  def do_at_exit
    puts "Exiting."
    unlock
    self.destroy
  end
  
  def work
    puts "Working..."
    check_in
    puts "Entering work routine."
    $instance = self
    loop do
      if !killed?
        work_routine
      else
        puts "Just nappin'."
        sleep(SLEEP_CONSTANT)
      end
    end
  end
  
  def work_routine
    @curation = select_curation
    update_counts
    update_curation
    #clean_orphans
    do_analysis_jobs
    @curation.unlock if @curation
  end
  
  def select_curation
    puts "select_curation..."
    curations = Curation.unlocked.all(:analyzed => false).reject {|c| c.datasets.collect {|d| d.scrape_finished }.include?(false) }.shuffle
    for curation in curations
      curation.lock
      return curation if curation.owned_by_me?
    end
    return nil
  end
  
  def update_counts
    puts "update_counts..."
    for dataset in Dataset.all(:scrape_finished => false)
      dataset.tweets_count = Tweet.count(:dataset_id => dataset.id)
      dataset.entities_count = Entity.count(:dataset_id => dataset.id)
      dataset.users_count = User.count(:dataset_id => dataset.id)
      dataset.save
    end
  end
  
  def update_curation
    puts "update_curation..."
    if @curation
      for dataset in @curation.datasets
        if dataset.users_count != User.count(:dataset_id => dataset.id)
          dataset.tweets_count = Tweet.count(:dataset_id => dataset.id)
          dataset.entities_count = Entity.count(:dataset_id => dataset.id)
          dataset.users_count = User.count(:dataset_id => dataset.id)
          dataset.save!
        end
      end
    end
  end
  
  def clean_orphans
    puts "clean_orphans..."
    begin
      Instance.all(:hostname => ENV['HOSTNAME']).each do |instance|
        if Sh::sh("kill -0 #{instance.pid}", false, false).select{|response| !response.empty?}.length == 1
          Lock.all(:instance_id => instance.instance_id).destroy
          instance.destroy
        end
      end
    rescue
      retry
    end
    Lock.all(:instance_id.not => Instance.all.collect{|instance| instance.instance_id}).destroy
  end
  
  def do_analysis_jobs
    puts "do_analysis_jobs..."
    # WARNING: TODO: rest_allowed not implemented yet
    while AnalysisMetadata.unlocked.count(:finished => false)!=0
      metadata = AnalysisMetadata.unlocked.first(:finished => false)
      metadata.lock
      if !metadata.nil? && metadata.owned_by_me?
        $instance.metadata = metadata
        route(metadata)
      end
    end
    puts "No analysis work to do right now."
  end
  
  def route(metadata)
    case metadata.language
    when "ruby"
      Analysis::Dependencies.send(metadata.function)
      puts "#{metadata.function.classify}.run(#{metadata.run_vars.join(", ")})"
      metadata.function.classify.constantize.run(*metadata.run_vars)
    else 
      raise "Language #{metadata.language} is not currently supported for analytical routing!"
    end
  end
end

worker = Worker.new
worker.work

