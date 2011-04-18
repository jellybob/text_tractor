require 'rspec'
require 'rack/test'
require 'capybara/rspec'
require 'text_tractor'
require 'redis'

TextTractor.config do |c|
  c.redis = {
    ns: "text_tractor:test",
    db: 8
  }

  c.environment = :test
  c.hostname = "example.host"
  c.port = 8000
  c.ssl = false
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Capybara
  
  conf.before(:each) do
    redis.flushdb
  end
  
  def redis
    TextTractor.redis
  end

  def app
    TextTractor.application
  end
  Capybara.app = app
  
  def login(username = nil, password = nil)
    username ||= TextTractor.configuration.default_username
    password ||= TextTractor.configuration.default_password
    
    basic_authorize username, password
    Capybara.current_session.driver.basic_authorize username, password
  end
  
  def create_user(username, password, superuser = false)
    TextTractor::Users.create(name: username, username: username, password: password, superuser: superuser)
  end

  def create_superuser(username, password)
    create_user(username, password, true)
  end
end
