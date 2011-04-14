require 'spec_helper'
require 'json'

describe "the UI server" do
  def app
    Copycat::UiServer
  end

  def redis
    @redis ||= Redis::Namespace.new(app.redis[:ns], :redis => Redis.new(app.redis))
  end

  before(:each) do
    redis.flushdb
  end
end
