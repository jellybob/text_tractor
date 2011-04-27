module TextTractor
  class ApiServer < TextTractor::Base
    # Used to defer returning a list of blurbs so that the ETag can be checked first.
    class BlurbList
      attr_reader :redis, :api_key, :state, :project
      
      def initialize(redis, api_key, state)
        @redis = redis
        @api_key = api_key
        @state = state
        @project = Projects.get(api_key)
      end
      
      def etag
        redis.get("projects:#{api_key}:#{state}_blurbs_etag") || ""
      end
      
      def blurbs
        project.blurbs(state)
      end
      
      def update(blurbs, options = {})
        project.update_blurbs(state, JSON.parse(blurbs), options)
      end
      
      def each
        yield blurbs.to_json
      end
    end
    
    def self.random_key
      Digest::MD5.hexdigest("#{Kernel.rand(9999999999999)}.#{Time.now.to_i}")
    end
    
    def project(api_key)
      Projects.get(api_key)
    end
  
    def project_exists?(api_key)
      redis.sismember "projects", api_key
    end
    
    def project_not_found(api_key)
      [ 404, { "error" => "No project has the API key #{api_key}." }.to_json ]
    end
    
    # Marks all draft blurbs as published
    post '/:api_key/deploys' do |api_key|
      return project_not_found(api_key) unless project_exists?(api_key)

      draft = BlurbList.new(redis, api_key, "draft")
      published = BlurbList.new(redis, api_key, "published")
      published.update draft.blurbs.to_json, :overwrite => true
      
      [ 200, "OK" ]
    end
    
    # Returns the list of blurbs
    get %r{/([\w]+)/([\w]+)_blurbs} do |api_key, state|
      return project_not_found(api_key) unless project_exists?(api_key)
      
      blurbs = BlurbList.new(redis, api_key, state)
      [ 200, { "ETag" => blurbs.etag }, blurbs ]
    end
    
    # Updates the list of blurbs
    #
    # Once created a blurb can not be updated via the API.
    post %r{/([\w]+)/([\w]+)_blurbs} do |api_key, state|
      return project_not_found(api_key) unless project_exists?(api_key)
      
      blurbs = BlurbList.new(redis, api_key, state)
      blurbs.update(params.reject { |k, v| k == "api_key" }.keys.first)
      
      [ 200, "OK" ]
    end
    
    # Returns the list of projects.
    get "/" do
      redis.smembers("projects").collect { |p| project(p) }.to_json
    end
    
    # Creates a new project
    post "/" do
      begin
        project = Projects.create(params)
        project.to_json
      rescue Projects::DuplicateProjectName => e
        [ 422, { "error" => "The project name you specified is already in use." }.to_json ]
      end
    end
  end
end
