require 'copycat/version'
require 'copycat/base'
require 'copycat/api_server'
require 'copycat/ui_server'

module Copycat
  def self.application
    Rack::URLMap.new \
      "/" => Copycat::UiServer.new,
      "/api/v2/projects" => Copycat::ApiServer.new
  end
end
