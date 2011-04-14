require "rubygems"
require "bundler/setup"
require "uri"
require "copycat"

Copycat.config do |c|
  # You should change these.
  c.default_username = "admin"
  c.default_password = "password"
  
  # This can also be set using a hash.
  c.redis = ENV["REDISTOGO_URL"] if ENV.key? "REDISTOGO_URL"
end

run Copycat.application
