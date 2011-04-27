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
        attributes["default_locale"] ||= "en"
        
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
        translations = JSON.parse(redis.get("projects:#{api_key}:#{state}_blurbs:#{key}"))
        translations.each do |locale, value|
          blurbs["#{locale}.#{key}"] = value
        end
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
    def self.update_blurb(state, api_key, locale, phrase, value, overwrite = false)
      key = "projects:#{api_key}:#{state}_blurbs:#{phrase}"
      written = false
      
      current_value = redis.sismember("projects:#{api_key}:#{state}_blurb_keys", phrase) ? JSON.parse(redis.get(key)) : {}
      
      if overwrite || !current_value.key?(locale)
        current_value[locale] = value
        write = true
      end

      if write
        redis.sadd "projects:#{api_key}:#{state}_blurb_keys", phrase
        redis.set key, current_value.to_json
        redis.set "projects:#{api_key}:#{state}_blurbs_etag", random_key
      end

      write
    end

    def self.update_blurbs(state, api_key, blurbs = {}, options = {})
      options[:overwrite] = false if options[:overwrite].nil?
      
      changed = false
      blurbs.each do |key, value|
        locale, phrase = key.split(".", 2)
        
        # TODO: Extract this... six arguments to a method is just too many!
        update_blurb(state, api_key, locale, phrase, value, options[:overwrite])
      end
      
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
