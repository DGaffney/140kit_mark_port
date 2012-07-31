load File.dirname(__FILE__)+'/../environment.rb'
class Importer < Instance

  MAX_TRACK_IDS = 10000
  BATCH_SIZE = 100
  
  attr_accessor :user_account, :username, :password, :next_dataset_ends, :queue, :params, :datasets, :start_time, :last_start_time

  def initialize
    super
    @datasets = []
    @queue = []
    @start_time = Time.now
    self.import
    at_exit { do_at_exit }
  end
  

  def import
    while true
      importer_tasks = ImporterTask.unlocked.all(:finished => false)
      importer_tasks.each do |importer_task|
        importer_task.import
      end
    end
  end

  def self.generate_default_importer_tasks(dataset_id, curation_id)
    dataset = Dataset.get(dataset_id)
    curation = Curation.get(curation_id)
    models = Sh::ls(STORAGE["path"])
    files = []
    pwd = Sh::storage_bt("pwd")[0]
    filepath = STORAGE["path"]
    models.each do |model|
      model_files = Sh::storage_ls(filepath+"/"+model).select{|f| f[0] == dataset_id.to_s}
      files = files+model_files.collect{|file| pwd+"/"+filepath+"/"+model+"/"+file}
    end
    importer_tasks = []
    files.each do |file|
      importer_tasks << {:file_location => file, :type => "single_file", :researcher_id => curation.researcher_id, :dataset_id => dataset.id, :finished => false}
    end
    ImporterTask.save_all(importer_tasks)
  end
end
i = Importer.new
i.import
