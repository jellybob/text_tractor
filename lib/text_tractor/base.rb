require 'sinatra'
require 'json'
require 'redis'
require 'redis-namespace'
require 'digest/md5'
require 'rack/etag'

module TextTractor
  class Base < Sinatra::Application
    use Rack::ETag
    use Rack::ConditionalGet
    
    def initialize(app=nil)
      super
    end

    def redis
      TextTractor.redis
    end

    def not_authorised
      [ 403, "Not Authorised" ]
    end
  end
end
