require 'rspec'
require 'rack/test'
require 'copycat'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
