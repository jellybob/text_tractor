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
    
    set :redis, {
      :ns => "copycat",
      :host => "localhost",
      :port => 6379
    }

    def initialize(app=nil)
      super
      @redis = Redis.new(settings.redis)
      @nsredis = Redis::Namespace.new(settings.redis[:ns], :redis => @redis)
    end

    def redis
      @nsredis
    end
  end
end
