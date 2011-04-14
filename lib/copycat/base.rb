require 'sinatra'
require 'json'
require 'redis'
require 'redis-namespace'
require 'digest/md5'
require 'rack/etag'

module Copycat
  class Base < Sinatra::Application
    use Rack::ETag
    use Rack::ConditionalGet
    
    def initialize(app=nil)
      super
      @redis = Redis.new(Copycat.configuration.redis)
      @nsredis = Redis::Namespace.new(Copycat.configuration.redis[:ns], :redis => @redis)
    end

    def redis
      @nsredis
    end
  end
end
