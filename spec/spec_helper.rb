require 'rspec'
require 'rack/test'
require 'capybara/rspec'
require 'copycat'
require 'redis'

Copycat.config do |c|
  c.redis = {
    ns: "copycat:test",
    db: 8
  }

  c.environment = :test
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Capybara
  
  conf.before(:each) do
    redis.flushdb
  end
  
  def redis
    Copycat.redis
  end

  def app
    Copycat.application
  end
  Capybara.app = app
  
  def login
    basic_authorize Copycat.configuration.default_username, Copycat.configuration.default_password
  end
  
  def login_for_capybara(username = nil, password = nil)
    username ||= Copycat.configuration.default_username
    password ||= Copycat.configuration.default_password
    
    Capybara.current_session.driver.basic_authorize username, password
  end

  def create_user(username, password, superuser = false)
    login
    post "/users", {
      "username" => username,
      "password" => password,
      "superuser" => superuser,
      "name" => username
    }
  end

  def create_superuser(username, password)
    create_user(username, password, true)
  end
end
