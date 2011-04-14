require "rubygems"
require "bundler/setup"
require "copycat/api_server"

run Rack::URLMap.new \
  "/api/v2/projects" => Copycat::ApiServer.new
