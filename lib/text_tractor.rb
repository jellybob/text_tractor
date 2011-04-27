require 'text_tractor/version'
require 'text_tractor/config'
require 'text_tractor/projects'
require 'text_tractor/users'
require 'text_tractor/base'
require 'text_tractor/api_server'
require 'text_tractor/ui_server'

module TextTractor
  def self.application
    UiServer.set :environment, config.environment
    ApiServer.set :environment, config.environment
    
    Rack::URLMap.new \
      "/" => UiServer.new,
      "/api/v2/projects" => ApiServer.new
  end

  def self.redis
    @redis ||= Redis.new(configuration.redis)
    @namespaced_redis ||= Redis::Namespace.new(configuration.redis[:ns], :redis => @redis)
  end

  def self.stringify_keys(hash)
    hash = hash.inject({}) do |tmp, item|
      tmp[item[0].to_s] = item[1] # Convert symbolized keys to strings.
      tmp
    end
  end
end
