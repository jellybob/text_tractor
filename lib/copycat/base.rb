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
    end

    def redis
      Copycat.redis
    end
  end
end
