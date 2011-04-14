require "rubygems"
require "bundler/setup"
require "uri"
require "copycat"

# You should change these.
Copycat::UiServer.set :default_username, "admin"
Copycat::UiServer.set :default_password, "password"

if ENV.key? "REDISTOGO_URL"
  uri = URI.parse(ENV["REDISTOGO_URL"])
  Copycat::UiServer.set :redis, {
    :host => uri.host,
    :port => uri.port,
    :password => uri.password,
    :username => uri.user
  }
  Copycat::ApiServer.set :redis, Copycat::UiServer.settings.redis
end

run Copycat.application
