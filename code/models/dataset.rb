class Dataset
  include DataMapper::Resource
  property :id, Serial
  property :scrape_type, String, :index => [:scrape_type]
  property :created_at, Time
  property :updated_at, Time
  property :scrape_finished, Boolean, :default => false
  property :instance_id, String, :index => [:instance_id]
  property :params, Object
  property :tweets_count, Integer, :default => 0
  property :users_count, Integer, :default => 0
  property :entities_count, Integer, :default => 0
  property :tweets_missed, Integer, :default => 0
  property :valid_tweets_missed, Integer, :default => 0
  property :status, String, :default => "tsv_storing"
  property :storage_machine_id, Integer
  has n, :tweets
  has n, :users
  has n, :curations, :through => Resource
  has 1, :importer_task
  
  def curation
    curations.first(:single_dataset => true)
  end
  
  def self.scrape_types
    ['track', 'follow', 'locations', 'sample', 'import']
  end
  
  def self.valid_params(scrape_type, params)
    response = {}
    response[:reason] = ""
    response[:clean_params] = ""
    case scrape_type
    when "track"
      term = (params.split(",")[0..params.split(",").length-1]).join(",")
      response[:reason] = "The term must contain one letter or number" if term.strip.empty?
      response[:reason] = "The term can't be empty" if term.strip.empty?
      #break if !response[:reason].empty?
      response[:original] = params
      response[:clean_params] = term
    when "follow"
      users = params.split(",")[0..params.split(",").length-1]
      ids = []
      users.each do |user|
        user_id = Twit.user(user).id rescue 0
        ids << user_id if user_id != 0
        if user_id == 0
          response[:reason] = "No User found with name #{user}"
          return response
        end
      end
      response[:reason] = "The follow list contained no users" if ids.empty?
      response[:original] = params
      response[:clean_params] = ids.join(",")
    when "locations"
      boundings = (params.split(",")[0..params.split(",").length-1]).collect{|b| b.to_f}
      (response[:reason] = "Must input two pairs of numbers, separated by commas.";return response) if boundings.length!=4
      (response[:reason] = "Total Area of this box is zero - must make a real box";return response) if boundings.area==0
      (response[:reason] = "Latitudes are out of range (max 90 degrees)";return response) if boundings[1].abs>90 || boundings[3].abs>90
      (response[:reason] = "Longitudes are out of range (max 180 degrees)";return response) if boundings[0].abs>180 || boundings[2].abs>180
      #break if !response[:reason].empty?
      response[:original] = params
      response[:clean_params] = boundings.join(",")
    when "sample"
      return params
    end
    return response
  end
  
  def full_delete
    Tweet.all(:dataset_id => self.id).destroy
    Entity.all(:dataset_id => self.id).destroy
    User.all(:dataset_id => self.id).destroy
    Friendship.all(:dataset_id => self.id).destroy
    ImporterTask.all(:dataset_id => self.id).destroy
    Geo.all(:dataset_id => self.id).destroy
    Coordinate.all(:dataset_id => self.id).destroy
    self.destroy
  end
  
  def internal_params_label
    return self.params
  end
  
  def time_range_overlap(other_dataset)
    if self.params[:time] == -1
      if other_dataset.params[:time] == -1
        return (self.created_at.to_i..Time.now.to_i).include?(other_dataset.created_at.to_i) || (self.created_at.to_i..Time.now.to_i).include?(Time.now.to_i)
      else
        return (self.created_at.to_i..Time.now.to_i).include?(other_dataset.created_at.to_i) || (self.created_at.to_i..Time.now.to_i).include?((other_dataset.created_at+other_dataset.params[:time]).to_i)
      end
    else
      return (self.created_at.to_i..self.created_at.to_i+self.params[:time]).include?(other_dataset.created_at.to_i) || (self.created_at.to_i..self.created_at.to_i+self.params[:time]).include?((other_dataset.created_at+other_dataset.params[:time]).to_i)
    end 
  end
end
