require 'spec_helper'

describe "authentication" do
  it "rejects the request if no authentication was provided" do
    get "/"
    last_response.status.should eq 401
  end
  
  it "allows access if logging in with the default credentials" do
    Copycat::UiServer.set :default_username, "admin"
    Copycat::UiServer.set :default_password, "password"
    
    basic_authorize "admin", "password"
    
    get "/"
    last_response.status.should eq 200
  end
end
