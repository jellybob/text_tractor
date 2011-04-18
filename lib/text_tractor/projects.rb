module TextTractor
  module Projects
    class DuplicateProjectName < Exception; end
    
    def self.redis
      TextTractor.redis
    end
    
    def self.random_key
      Digest::MD5.hexdigest("#{Kernel.rand(9999999999999)}.#{Time.now.to_i}")
    end
    
    def self.exists?(api_key)
      redis.sismember "projects", api_key
    end
    
    def self.create(attributes = {})
      attributes = TextTractor.stringify_keys(attributes)
      
      if redis.sismember "project_names", attributes["name"]
        raise DuplicateProjectName.new
      else
        attributes["api_key"] ||= random_key
        
        redis.set "projects:#{attributes["api_key"]}", attributes.to_json
        redis.sadd "projects", attributes["api_key"]
        redis.sadd "project_names", attributes["name"]
        if attributes["users"]
          attributes["users"].each { |user| assign_user(user, attributes["api_key"]) }
        end
        
        attributes
      end
    end
    
    def self.assign_user(user, api_key)
      if redis.sismember "projects", api_key
        redis.sadd "project_users:#{api_key}", user
      end
    end

    def self.get(api_key)
      json = redis.get("projects:#{api_key}")
      return JSON.parse(json) if json
    end
    
    def self.blurbs(state, api_key)
      return nil unless exists?(api_key)
      
      blurbs = {}
      redis.smembers("projects:#{api_key}:#{state}_blurb_keys").each do |key|
        blurbs[key] = redis.get "projects:#{api_key}:#{state}_blurbs:#{key}"
      end

      blurbs
    end

    def self.draft_blurbs(api_key)
      blurbs("draft", api_key)
    end

    def self.published_blurbs(api_key)
      blurbs("published", api_key)
    end
    
    # Set the :overwrite option to true to force overwriting existing translations.
    def self.update_blurbs(state, api_key, blurbs = {}, options = {})
      options[:overwrite] = false if options[:overwrite].nil?
      
      changed = false
      blurbs.each do |key, value|
        full_key = "projects:#{api_key}:#{state}_blurbs:#{key}"
        written = false
       
        # This isn't ideal, but using redis.send(method, key, value) doesn't seem to work.
        if options[:overwrite]
          redis.set(full_key, value)
          written = true
        else
          written = redis.setnx(full_key, value)
        end

        if written
          redis.sadd "projects:#{api_key}:#{state}_blurb_keys", key
          changed = true
        end
      end
      
      redis.set "projects:#{api_key}:#{state}_blurbs_etag", random_key if changed
      
      true
    end

    def self.update_draft_blurbs(api_key, blurbs = {}, options = {})
      update_blurbs "draft", api_key, blurbs, options
    end
    
    def self.update_published_blurbs(api_key, blurbs = {}, options = {})
      update_blurbs "published", api_key, blurbs, options
    end
    
    def self.for_user(user)
      projects = []
      redis.smembers("projects").each do |p|
        projects << get(p) if authorised? user, p
      end

      projects.sort { |a, b| a["name"] <=> b["name"] }
    end

    def self.authorised?(user, api_key)
      user["superuser"] || redis.sismember("project_users:#{api_key}", user["username"])
    end

    def self.configuration_block(project)
      <<EOF
      Copycopter::Client.configure do |config|
  config.api_key = "#{project["api_key"]}"
  config.host    = "#{TextTractor.configuration.hostname}"
  config.port    = #{TextTractor.configuration.port}
  config.secure  = #{TextTractor.configuration.ssl ? "true" : "false"}
end
EOF
    end
  end
end
