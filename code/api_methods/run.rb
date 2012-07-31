load File.dirname(__FILE__)+'/../environment.rb'
@count = 0
@start_time = Time.now
CHECK_FOR_NEW_DATASETS_INTERVAL = 60*60*24*2
TweetStream.configure do |config|
  config.consumer_key = "RBY3pMQVAYbHW3Eld1DUg"
  config.consumer_secret = "SyaJ6osRIQb3O4vsKsnNJoI31tWAhBYhgCQYS04"
  config.oauth_token = "148584489-8qB2SzclXvglJcuCKe5JdqDX1fruGa12ftnQLBJj"
  config.oauth_token_secret = "FobF7iibpFGU7HtYlfsR7fKR2q06R9fjsbSygbm2cU"
  config.auth_method = :oauth
end
client = TweetStream::Client.new
client.on_interval(CHECK_FOR_NEW_DATASETS_INTERVAL) {@start_time = Time.now; puts "Switching to new files..."}
client.on_limit { |skip_count| puts "\nWe are being rate limited! We lost #{skip_count} tweets!"}
client.on_error { |message| puts "\nError: #{message}\n"}
client.sample do |json|
  t = Time.now
  dataset_id = 194
  tweet, user = TweetHelper.prepped_tweet_and_user(json)
  geo = GeoHelper.prepped_geo(json)
  tweet.merge!({:dataset_id => dataset_id})
  user.merge!({:dataset_id => dataset_id})
  geo.merge!({:dataset_id => dataset_id})
  coordinates = CoordinateHelper.prepped_coordinates(json).collect{|coordinate| coordinate.merge({:dataset_id => dataset_id})}.flatten
  entities = EntityHelper.prepped_entities(json).collect{|entity| entity.merge({:dataset_id => dataset_id})}.flatten
  Tweet.store_to_flat_file([tweet], "/home/devin/code/api_methods/results/#{Tweet}/#{dataset_id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}")
  User.store_to_flat_file([user], "/home/devin/code/api_methods/results/#{User}/#{dataset_id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}")
  Geo.store_to_flat_file([geo], "/home/devin/code/api_methods/results/#{Geo}/#{dataset_id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}")
  Coordinate.store_to_flat_file(coordinates, "/home/devin/code/api_methods/results/#{Coordinate}/#{dataset_id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}")
  Entity.store_to_flat_file(entities, "/home/devin/code/api_methods/results/#{Entity}/#{dataset_id}_#{@start_time.strftime("%Y-%m-%d_%H-%M-%S")}")
  @count+=1
  tt = Time.now-t
  puts "Saved total of #{@count} (#{tt})"
end

