require "rubygems"
require "bundler/setup"
require "uri"
require "text_tractor"

TextTractor.config do |c|
  # You should change these.
  c.default_username = "admin"
  c.default_password = "password"
  
  c.hostname = "text_tractor.example.org"
  c.port = 443
  c.ssl = true
   
  # This can also be set using a hash.
  c.redis = ENV["REDISTOGO_URL"] if ENV.key? "REDISTOGO_URL"
end

run TextTractor.application
