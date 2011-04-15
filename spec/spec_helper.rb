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
  
  def login(username = nil, password = nil)
    username ||= Copycat.configuration.default_username
    password ||= Copycat.configuration.default_password
    
    basic_authorize username, password
    Capybara.current_session.driver.basic_authorize username, password
  end
  
  def create_user(username, password, superuser = false)
    Copycat::Users.create(name: username, username: username, password: password, superuser: superuser)
  end

  def create_superuser(username, password)
    create_user(username, password, true)
  end
end
