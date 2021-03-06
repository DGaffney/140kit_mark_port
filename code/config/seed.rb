# advanced_histogram = AnalyticalOffering.create(:title => "Advanced Histograms", :function => "advanced_histogram", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Advanced Histograms")
# advanced_histogram_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> advanced_histogram.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# audience_comparison = AnalyticalOffering.create(:title => "Audience Comparisons", :function => "audience_comparison", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Advanced Histograms")
# audience_comparison_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> audience_comparison.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# basic_histogram = AnalyticalOffering.create(:title => "Basic Histograms", :function => "basic_histogram", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Create basic histograms for all quantifiable attributes for users and tweets in the data set. Example: All users have follower counts (the number of people following them); this matches the number of followers to the number of users that have that many followers. With tweet's created_at time stamp, the number tweets created at every time step is created in a simple graph format. This data is then available in the collection view of your data set; you can then consume this information as google charts (with embed code included) data, JSON, CSV, or XML.")
# basic_histogram_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> basic_histogram.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# edge_generator = AnalyticalOffering.create(:title => "Edge Generator", :function => "edge_generator", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Generates all edges of types mention, retweet, and friendship")
# edge_generator_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "string", :analytical_offering_id=> edge_generator.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# gender_estimation = AnalyticalOffering.create(:title => "Gender Estimation", :function => "gender_estimation", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "This Analytic pings the TrueKnowledge.com database to find out if a user's name (not their Username, but the name that they put in as their actual name) is either typically Male or Female. If it cannot conclusively attach a gender to the name, it reports the name as Inconclusive. In short, if it DOES select a name, it is very likely that the gender guess is accurate.")
# gender_estimation_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> gender_estimation.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# gender_estimation_var_1 = AnalyticalOfferingVariableDescriptor.create(:name => "sample_size", :position => 1, :kind => "integer", :analytical_offering_id=> gender_estimation.id, :description => "Sample size for the gender estimation to be calculated on. Default is 10%", :user_modifiable => true)
# 
# mysql_dumper = AnalyticalOffering.create(:title => "MYSQL Dumper", :function => "mysql_dumper", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Dump all the data from your collection into .sql files, which are then available on our file system on the server for ever and ever. It's always a bad idea to have no back-ups of data; it's even worse to not have redundant data. This allows you to create your own MySQL database with all your tweets and users intact (and mapped to one another with our indices) without losing a beat so that you can do whatever you will with the data separately and off of our site in case we don't have the analytics you want.")
# mysql_dumper_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> mysql_dumper.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# network_grapher = AnalyticalOffering.create(:title => "Network Grapher", :function => "network_grapher", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Generates network graphs in gexf and graphml of either mentions/retweets, friendships, or both.")
# network_grapher_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "string", :analytical_offering_id=> network_grapher.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# network_grapher_var_1 = AnalyticalOfferingVariableDescriptor.create(:name => "graph_type", :position => 1, :kind => "string", :analytical_offering_id=> network_grapher.id, :description => "What type of network graph will be generated ('conversational_tweets','friendships','multivariate')", :user_modifiable => true)
# 
# raw_csv = AnalyticalOffering.create(:title => "Raw CSV", :function => "raw_csv", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Dump all the data from your collection into .csv files, which are then available on our file system on the server for ever and ever. With CSV, you can easily open up the data in Excel, OpenOffice (god bless you), or something similar, or just push it into some other data base solution as this is one of the most simple forms of transitioning data from one place to another. Allows for simple access to the data without much thought put into it, and gets you rolling on your own research.")
# raw_csv_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> raw_csv.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# csv_export = AnalyticalOffering.create(:title => "CSV Export", :function => "csv_export", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "CSV Export allows you to specify a model and fields to pull data from.")
# csv_export_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> csv_export.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# csv_export_var_1 = AnalyticalOfferingVariableDescriptor.create(:name => "model", :position => 1, :kind => "string", :analytical_offering_id=> csv_export.id, :description => "The model that will be pulled from.", :user_modifiable => true)
# csv_export_var_2 = AnalyticalOfferingVariableDescriptor.create(:name => "fields", :position => 2, :kind => "string", :analytical_offering_id=> csv_export.id, :description => "The fields, separated by commas, that will be plucked from the model", :user_modifiable => true)
# 
# gis_export = AnalyticalOffering.create(:title => "GIS CSV Export", :function => "gis_export", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Pull out fields that are useful for GIS analysis.")
# gis_export_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> gis_export.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# time_based_summary = AnalyticalOffering.create(:title => "Time Based Summary", :function => "time_based_summary", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "Break your histograms (and resultant CSVs) into smaller pockets of time - want to see the specific traffic for one hour's worth of data? You sould look at it by navigating to the Year/Month/Day/Hour location of the folder structure resulting from a Time-Based summary, and be able to look at all the basic histograms usually available.")
# time_based_summary_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> time_based_summary.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# time_based_summary_var_1 = AnalyticalOfferingVariableDescriptor.create(:name => "granularity", :position => 1, :kind => "string", :analytical_offering_id=> time_based_summary.id, :description => "Granularity to set time based reports on. Select from ['year','month','day','hour']", :user_modifiable => true)
# 
# word_frequencies = AnalyticalOffering.create(:title => "Word Frequencies", :function => "word_frequency", :language => "ruby", :created_by => "140kit Team", :created_by_link => "http://140kit.com", :access_level => "user", :description => "The Word Frequency Analytic reads through your collection of tweets and keeps track of the number of occurrences of each word. From there, it breaks this 'Word Frequency hash' into four distinct categories: Hashtags, Mentions, Non-Stop Words (excluding words like 'it', 'the', 'he', 'she', etc..), and Links. It then pushes charts of the frequencies of occurrence into a Google Charts table so you can easily go through the results - raw CSVs of this data are also available. In other words, when you include this Analytic, you are able to quickly see the most often-used Hashtags, Links, Usernames, and Words in order to quickly get a high-level overview of the data")
# word_frequencies_var_0 = AnalyticalOfferingVariableDescriptor.create(:name => "curation_id", :position => 0, :kind => "integer", :analytical_offering_id=> word_frequencies.id, :description => "Curation ID for set to be analyzed", :user_modifiable => false)
# 
# 
# audience_profiler = WorkerDescription.create(:name => "Audience Profiler", :filename => "audience_profiler", :description => "Given a params of a username, this dataset collection algorithm pulls data from all the people following the account (the audience), including the 200 most recent tweets from the followers.", :type => "collector", :active => false)
# audience_profiler_0 = Parameter.create(:worker_description_id => audience_profiler.id, :name => "Screen Name", :position => 0, :description => "Enter the valid Screen Name of a user on Twitter", :active => true)
# importer = WorkerDescription.create(:name => "Importer", :filename => "importer", :description => "Given an import type (can be '140kit', 'CSV', 'SQL') and a location for the files or unique identification for it (URLs for CSV or SQL, an ID for 140kit), this algorithm resurrects or imports a dataset into the current system.", :type => "collector", :active => false)
# importer_0 = Parameter.create(:worker_description_id => importer.id, :name => "Source", :position => 0, :description => "Enter the name of the source (can be '140kit', 'CSV', 'SQL')", :active => false)
# importer_1 = Parameter.create(:worker_description_id => importer.id, :name => "Identifier", :position => 1, :description => "Enter the unique identifier for the data source. If its a file, a URL will suffice. If its an old dataset from 140kit, please supply the ID of the dataset", :active => false)
# track = WorkerDescription.create(:name => "Track", :filename => "track", :description => "Given a term as the parameter, this system collects tweets and users and entities from tweets containing that term for a given length of time", :type => "collector", :active => true)
# track_0 = Parameter.create(:worker_description_id => track.id, :name => "Term", :position => 0, :description => "Enter the term (can be any single word, phrase, hashtag, or Screen Name).", :active => true)
# track_1 = Parameter.create(:worker_description_id => track.id, :name => "Length", :position => 1, :description => "Enter amount of time, in seconds, that you would like this term to be searched for.", :active => true)
# follow = WorkerDescription.create(:name => "Follow", :filename => "follow", :description => "Given a screen name as a parameter, this system collects tweets and entities from tweets posted by that user for a given length of time", :type => "collector", :active => true)
# follow_0 = Parameter.create(:worker_description_id => follow.id, :name => "Screen Name", :position => 0, :description => "Enter the screen name of the user of interest (must be a user who has not privatized their account).", :active => true)
# follow_1 = Parameter.create(:worker_description_id => follow.id, :name => "Length", :position => 1, :description => "Enter amount of time, in seconds, that you would like this term to be searched for.", :active => true)
# locations = WorkerDescription.create(:name => "Locations", :filename => "locations", :description => "Given a set of cour geograph points (making a total area of less than 1 square degree) this system collects tweets and users and entities from tweets posted from that location for a given length of time", :type => "collector", :active => true)
# locations_0 = Parameter.create(:worker_description_id => locations.id, :name => "Geo Region", :position => 0, :description => "Enter the term (can be any single word, phrase, hashtag, or Screen Name).", :active => true)
# locations_1 = Parameter.create(:worker_description_id => locations.id, :name => "Length", :position => 1, :description => "Enter amount of time, in seconds, that you would like this term to be searched for.", :active => true)
# worker = WorkerDescription.create(:name => "Worker", :filename => "worker", :description => "This is the general purpose worker that is responsible for analyzing data.", :type => "analyzer", :active => true)
# 
# welcome = Post.create(:title => "Welcome to 140kit!", :slug => "welcome", :text => "Welcome to 140kit. Modify this landing page, if you so desire.", :created_at => Time.now, :researcher_id => researcher.id)

researcher = Researcher.create(:user_name => "oii", :email => "oii@internet.com", :role => "Admin", :join_date => Time.now, :info => "default user", :website_url => "http://oii.ox.ac.uk", :location => "The Internet", :salt => "fe648dff9e2067d0c4f42d9cc5568912ffca5dac", :crypted_password => "96df4f59f5e37a3da84f449940cd0bd87651e2e2")
researcher.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper0", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper1", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper2", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper3", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper4", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper5", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
auth_user = AuthUser.create(:screen_name => "oiiscraper6", :password => "143c9831b551fd1056a0bc86ca50402f2a24ae992efe15a6b40cb24cca0a0fb1")
auth_user.save!
Setting.create(:name => 'user_role_tweet_limit', :var_type => 'Admin', :var_class => 'integer', :value => 20000000)
Setting.create(:name => 'user_role_tweet_limit', :var_type => 'User', :var_class => 'integer', :value => 20000)
Setting.create(:name => 'user_role_tweet_limit', :var_type => 'Academic', :var_class => 'integer', :value => 500000)
Setting.create(:name => 'user_role_tweet_limit', :var_type => 'Commercial Account', :var_class => 'integer', :value => 200000)
Setting.create(:name => 'user_role_tweet_limit', :var_type => 'Inactive', :var_class => 'integer', :value => 0)
Setting.create(:name => 'user_role_tweet_limit', :var_type => 'Suspended', :var_class => 'integer', :value => 0)
Setting.create(:name => 'max_track_ids', :var_type => 'Filter Setting', :var_class => 'integer', :value => 10000)
Setting.create(:name => 'batch_size', :var_type => 'Filter Setting', :var_class => 'integer', :value => 100)
Setting.create(:name => 'check_for_new_datasets_interval', :var_type => 'Filter Setting', :var_class => 'integer', :value => 30)
Setting.create(:name => 'rsync_interval', :var_type => 'Filter Setting', :var_class => 'integer', :value => 1800)
Setting.create(:name => 'statuses', :var_type => 'Dataset Settings', :var_class => 'array', :value => ["tsv_storing", "tsv_stored", "needs_import", "imported", "live", "needs_drop", "dropped", "zero_data", "hidden"])
Setting.create(:name => 'unflippable_statuses', :var_type => 'Dataset Settings', :var_class => 'array', :value => ["zero_data", "imported", "tsv_stored", "dropped", "hidden"])
Setting.create(:name => 'sleep_constant', :var_type => 'Instance Settings', :var_class => 'integer', :value => 30)
Setting.create(:name => 'drop_interval', :var_type => 'Worker Setting', :var_class => 'integer', :value => 86400)
Setting.create(:name => 'hide_interval', :var_type => 'Worker Setting', :var_class => 'integer', :value => 2419200)
Setting.create(:name => 'clean_orphan_interval', :var_type => 'Worker Setting', :var_class => 'integer', :value => 900)
Setting.create(:name => 'roles', :var_type => 'User Roles', :var_class => 'array', :value => ["Inactive", "Suspended", "User", "Academic", "Admin"])
Setting.create(:name => 'maximum_user_search', :var_type => 'User', :var_class => 'integer', :value => 10)
Setting.create(:name => 'maximum_user_search', :var_type => 'Academic', :var_class => 'integer', :value => 100)
Setting.create(:name => 'maximum_user_search', :var_type => 'Admin', :var_class => 'integer', :value => 1000)