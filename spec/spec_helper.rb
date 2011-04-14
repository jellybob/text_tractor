require 'rspec'
require 'rack/test'
require 'capybara/rspec'
require 'copycat'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include Capybara

  def app
    Copycat.application
  end

  def login
    basic_authorize Copycat::UiServer.settings.default_username, Copycat::UiServer.settings.default_password
  end
end
