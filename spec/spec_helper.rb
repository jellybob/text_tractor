require 'rspec'
require 'rack/test'
require 'capybara/rspec'
require 'copycat'
require 'redis'

Copycat::UiServer.set :environment, :test
Copycat::UiServer.set :redis, {
  :ns => "copycat:test",
  :db => 8
}

Copycat::ApiServer.set :environment, :test
Copycat::ApiServer.set :redis, Copycat::UiServer.settings.redis

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Capybara
  
  conf.before(:each) do
    redis.flushdb
  end
  
  def redis
    Redis.new(Copycat::UiServer.settings.redis)
  end

  def app
    Copycat.application
  end
  Capybara.app = app
  
  def login
    basic_authorize Copycat::UiServer.settings.default_username, Copycat::UiServer.settings.default_password
  end
  
  def login_for_capybara(username = nil, password = nil)
    username ||= Copycat::UiServer.settings.default_username
    password ||= Copycat::UiServer.settings.default_password
    
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
end
