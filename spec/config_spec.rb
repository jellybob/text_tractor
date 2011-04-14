require 'spec_helper'

describe Copycat::Config do
  describe "setting the application configuration" do
    specify { Copycat.should respond_to(:config) }
    
    it "yields an instance of Copycat::Config" do
      Copycat.config.should do |config|
        config.should be_a Copycat::Config
      end
    end
  end

  describe "available options" do
    it { should respond_to(:redis) }
    it { should respond_to(:default_username) }
    it { should respond_to(:default_password) }
    it { should respond_to(:environment) }
    it { should respond_to(:salt) }

    describe "setting the redis option" do
      it "defaults to an empty hash" do
        subject.redis.should == {}
      end
      
      it "uses the provided value if it is a Hash" do
        subject.redis = { :server => "foo" }
        subject.redis.should == { :server => "foo" }
      end

      it "extracts the relevant details is it is a String" do
        subject.redis = "redis://user:password@example.org:1234/namespace"
        subject.redis.should == {
          host: "example.org",
          port: 1234,
          username: "user",
          password: "password",
          ns: "namespace"
        }
      end
    end
  end
end
