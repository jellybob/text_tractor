module Copycat
  class ApiServer < Copycat::Base
    # Used to defer returning a list of blurbs so that the ETag can be checked first.
    class BlurbList
      attr_reader :redis, :api_key, :state
      
      def initialize(redis, api_key, state)
        @redis = redis
        @api_key = api_key
        @state = state
      end
      
      def etag
        redis.get("projects:#{api_key}:#{state}_blurbs_etag") || ""
      end
      
      def blurbs
        blurbs = {}
        redis.smembers("projects:#{api_key}:#{state}_blurb_keys").each do |key|
          blurbs[key] = redis.get "projects:#{api_key}:#{state}_blurbs:#{key}"
        end

        blurbs
      end
      
      def update(blurbs)
        changed = false
        JSON.parse(blurbs).each do |key, value|
          if redis.setnx "projects:#{api_key}:#{state}_blurbs:#{key}", value
            redis.sadd "projects:#{api_key}:#{state}_blurb_keys", key
            changed = true
          end
        end
        
        redis.set "projects:#{api_key}:#{state}_blurbs_etag", Copycat::ApiServer.random_key if changed
        
        true
      end
      
      def each
        yield blurbs.to_json
      end
    end
    
    def self.random_key
      Digest::MD5.hexdigest("#{Kernel.rand(9999999999999)}.#{Time.now.to_i}")
    end
    
    def project(api_key)
      Copycat::Projects.get(api_key)
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
      published.update draft.blurbs.to_json
      
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
        project = Copycat::Projects.create(params)
        project.to_json
      rescue Copycat::Projects::DuplicateProjectName => e
        [ 422, { "error" => "The project name you specified is already in use." }.to_json ]
      end
    end
  end
end
