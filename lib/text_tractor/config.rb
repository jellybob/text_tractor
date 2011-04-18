require 'uri'

module TextTractor
  def self.configuration
    @configuration ||= TextTractor::Config.new
  end

  def self.config
    yield self.configuration if block_given?
    self.configuration
  end

  class Config
    attr_accessor :redis, :environment, :default_username, :default_password, :salt, :hostname, :port, :ssl
    
    def redis
      @redis ||= {}
    end
    
    def redis=(value)
      if value.is_a? String
        uri = URI.parse(value)
        @redis = {
          host: uri.host,
          port: uri.port,
          username: uri.user,
          password: uri.password,
          ns: uri.path.gsub(/^\//, '')
        }
      else
        @redis = value
      end
    end

    def port
      @port ||= 80
    end
    
    def ssl=(value)
      @ssl = value
    end
    
    def ssl
      @ssl = true if @ssl.nil?
      @ssl
    end
  end
end
