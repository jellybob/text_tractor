module TextTractor
  class Project
    attr_accessor :name, :api_key, :default_locale, :users

    def initialize(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value)
      end
    end
    
    def redis
      TextTractor.redis
    end
    
    def api_key
      @api_key ||= Projects.random_key
    end
    
    def users
      @users || []
    end

    def default_locale
      @default_locale || "en"
    end
    
    def to_json(state = nil)
      # I don't know what the generator state is used for, but it gets passed sometimes. Just accepting it as an argument seems to be
      # enough to work in this situation.

      { "name" => name, "api_key" => api_key, "default_locale" => default_locale, "users" => users }.reject { |k,v| v.nil? }.to_json
    end

    def [](key)
      send(key)
    end
    
    # Set the overwrite option to true to force overwriting existing translations.
    def update_blurb(state, locale, phrase, value, overwrite = false)
      key = "projects:#{api_key}:#{state}_blurbs:#{phrase}"
      written = false
      
      current_value = redis.sismember("projects:#{api_key}:#{state}_blurb_keys", phrase) ? JSON.parse(redis.get(key)) : {}
      
      if overwrite || !current_value.key?(locale)
        current_value[locale] = value
        write = true
      end

      if write
        redis.sadd "projects:#{api_key}:#{state}_blurb_keys", phrase
        redis.sadd "projects:#{api_key}:locales", locale
        redis.set key, current_value.to_json
        redis.set "projects:#{api_key}:#{state}_blurbs_etag", Projects.random_key
      end

      write
    end

    def update_blurbs(state, blurbs = {}, options = {})
      options[:overwrite] = false if options[:overwrite].nil?
      
      changed = false
      blurbs.each do |key, value|
        locale, phrase = key.split(".", 2)
        update_blurb(state, locale, phrase, value, options[:overwrite])
      end
      
      true
    end

    def update_draft_blurbs(blurbs = {}, options = {})
      update_blurbs "draft", blurbs, options
    end
    
    def update_published_blurbs(blurbs = {}, options = {})
      update_blurbs "published", blurbs, options
    end
    
    def blurbs(state)
      blurbs = {}
      redis.smembers("projects:#{api_key}:#{state}_blurb_keys").each do |key|
        translations = JSON.parse(redis.get("projects:#{api_key}:#{state}_blurbs:#{key}"))
        translations.each do |locale, value|
          blurbs["#{locale}.#{key}"] = value
        end
      end

      blurbs
    end

    def draft_blurbs
      blurbs("draft")
    end

    def published_blurbs
      blurbs("published")
    end
    
    def phrases(state)
      phrases = {}
      redis.smembers("projects:#{api_key}:#{state}_blurb_keys").each do |key|
        phrases[key] = JSON.parse(redis.get("projects:#{api_key}:#{state}_blurbs:#{key}"))
      end

      phrases
    end
    
    def draft_phrases
      phrases("draft")
    end

    def published_phrases
      phrases("published")
    end
    
    def locales
      locales = redis.smembers("projects:#{api_key}:locales")
      locales ? locales.sort : []
    end
    
    def configuration_block
      <<EOF
      Copycopter::Client.configure do |config|
  config.api_key = "#{api_key}"
  config.host    = "#{TextTractor.configuration.hostname}"
  config.port    = #{TextTractor.configuration.port}
  config.secure  = #{TextTractor.configuration.ssl ? "true" : "false"}
end
EOF
    end
  end
  
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
        project = Project.new(attributes)
        
        redis.set "projects:#{project.api_key}", project.to_json
        redis.sadd "projects", project.api_key
        redis.sadd "project_names", project.name
        project.users.each { |user| assign_user(user, project.api_key) }
        
        project
      end
    end
    
    def self.assign_user(user, api_key)
      if redis.sismember "projects", api_key
        redis.sadd "project_users:#{api_key}", user
      end
    end

    def self.get(api_key)
      json = redis.get("projects:#{api_key}")
      return Project.new(JSON.parse(json)) if json
    end
    
    def self.for_user(user)
      projects = []
      redis.smembers("projects").each do |p|
        projects << get(p) if authorised? user, p
      end

      projects.reject { |p| p.nil? }.sort { |a, b| a.name <=> b.name }
    end

    def self.authorised?(user, api_key)
      user["superuser"] || redis.sismember("project_users:#{api_key}", user["username"])
    end

    def self.update_datastore
      redis.smembers("projects").each do |api_key|
        project = get(api_key)

        redis.smembers("projects:#{api_key}:draft_blurb_keys").each do |blurb|
          value = redis.get("projects:#{api_key}:draft_blurbs:#{blurb}")
          locale, phrase = blurb.split(".", 2)
          
          project.update_blurb("draft", locale, phrase, value, true)
          
          redis.del("projects:#{api_key}:draft_blurbs:#{blurb}")
          redis.srem("projects:#{api_key}:draft_blurb_keys", blurb)
        end
      end
    end
  end
end
