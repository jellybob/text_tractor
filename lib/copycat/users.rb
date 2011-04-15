require 'digest/md5'

module Copycat
  module Users
    class DuplicateUserError < Exception; end
    
    def self.redis
      Copycat.redis
    end
    
    def self.all
      redis.smembers("users").collect { |u| JSON.parse(redis.get("users:#{u}")) }.sort { |a, b| a["name"] <=> b["name"] }
    end
    
    def self.exists?(username)
      redis.sismember("users", username)
    end

    def self.authenticate(username, password)
      redis.sismember("user_hashes", hash_user(username, password))
    end
    
    def self.create(attributes = {})
      attributes = Copycat.stringify_keys(attributes)
      
      password = attributes.delete("password")
      attributes["superuser"] ||= false
   
      if redis.setnx("users:#{attributes["username"]}", attributes.to_json)
        redis.sadd("users", attributes["username"])
        redis.sadd("user_hashes", hash_user(attributes["username"], password))
      else
        raise DuplicateUserError.new
      end
      
      attributes
    end

    def self.get(username)
      raw = redis.get("users:#{username}")
      return JSON.parse(raw) if raw
    end

    private
      def self.hash_user(username, password)
        Digest::MD5.hexdigest("#{username}.#{password}.#{Copycat.configuration.salt}")
      end
  end
end
