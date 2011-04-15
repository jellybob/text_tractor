require 'copycat/version'
require 'copycat/config'
require 'copycat/projects'
require 'copycat/users'
require 'copycat/base'
require 'copycat/api_server'
require 'copycat/ui_server'

module Copycat
  def self.application
    Rack::URLMap.new \
      "/" => Copycat::UiServer.new,
      "/api/v2/projects" => Copycat::ApiServer.new
  end

  def self.redis
    @redis ||= Redis.new(Copycat.configuration.redis)
    @namespaced_redis ||= Redis::Namespace.new(Copycat.configuration.redis[:ns], :redis => @redis)
  end

  def self.stringify_keys(hash)
    hash = hash.inject({}) do |tmp, item|
      tmp[item[0].to_s] = item[1] # Convert symbolized keys to strings.
      tmp
    end
  end
end
