require 'spec_helper'
require 'json'

describe "the API server" do
  def app
    TextTractor::ApiServer
  end

  describe "creating and listing projects" do
    it "allows the creation of a new project, returning the details" do
      post "/", :name => "Test Project", :api_key => "49032804328090f8sd0fas0jds"

      last_response.should be_ok
      JSON.parse(last_response.body).should == {
        "name" => "Test Project",
        "api_key" => "49032804328090f8sd0fas0jds",
        "default_locale" => "en"
      }
    end

    it "includes a newly created project in the projects list" do
      post "/", :name => "Test Project", :api_key => "bob"
      get "/"

      JSON.parse(last_response.body).should == [
        { "name" => "Test Project", "api_key" => "bob", "default_locale" => "en" }
      ]
    end

    it "rejects a project with the same name as an existing project" do
      post "/", :name => "Test Project"
      post "/", :name => "Test Project"
      
      last_response.should_not be_ok
      last_response.status.should eq 422
      JSON.parse(last_response.body).should == {
        "error" => "The project name you specified is already in use."
      }
    end
  end

  describe "registering draft blurbs for a project" do
    context "when the project exists" do
      before(:each) do
        post "/", :name => "Test Project", :api_key => "test"
        
        # That's the format we get it in from copycopter_client
        post "/test/draft_blurbs", {
          "application.home.title" => "Home Page",
          "application.home.body" => "This is the home page.",
          "application.home.quoted" => "\"I would like to test quoting.\" said Jon."
        }.to_json
      end

      it "shows the update was OK" do
        last_response.should be_ok
        last_response.body.should == "OK"
      end
    end

    context "when the project does not exist" do
      it "returns a 404 error code" do
        post "/test/draft_blurbs"

        last_response.status.should eq 404
      end
    end
  end

  describe "returning the draft blurbs for a project" do
    context "when the project exists" do
      before(:each) do
        TextTractor::Projects.create name: "Test Project", api_key: "test"

        # That's the format we get it in from copycopter_client
        post "/test/draft_blurbs", {
          "application.home.title" => "Home Page",
          "application.home.body" => "This is the home page."
        }.to_json
      end

      it "returns all the translations if the ETag does not match" do
        get "/test/draft_blurbs"
        
        last_response.should be_ok
        JSON.parse(last_response.body).should == {
          "application.home.title" => "Home Page",
          "application.home.body" => "This is the home page."
        }
      end
      
      it "returns a status code of 302, with an empty body, if the ETag does match" do
        header "If-None-Match", redis.get("projects:test:draft_blurbs_etag")
        get "/test/draft_blurbs"

        last_response.status.should eq 304
        last_response.body.should be_empty
      end
      
      it "does not load the translation list if the ETag matches" do
        blurbs = stub(:bytesize => 0, :etag => "foo")
        TextTractor::ApiServer::BlurbList.should_receive(:new).and_return(blurbs)
        blurbs.should_not_receive(:each)
        
        header "If-None-Match", "foo"
        get "/test/draft_blurbs"

        last_response.status.should eq 304
        last_response.body.should be_empty
      end

      it "sets the ETag to be set" do
        get "/test/draft_blurbs"

        last_response.headers["ETag"].should_not be_nil
        last_response.headers["ETag"].should == redis.get("projects:test:draft_blurbs_etag")
      end
    end

    context "when the project does not exist" do
      it "returns a 404 error code" do
        get "/test/draft_blurbs"

        last_response.status.should eq 404
      end
    end
  end

  describe "returning the published blurbs for a project" do
    context "when the project exists" do
      before(:each) do
        TextTractor::Projects.create name: "Test Project", api_key: "test"

        post "/test/published_blurbs", {
          "application.home.title" => "Home Page",
          "application.home.body" => "This is the home page."
        }.to_json
      end

      it "returns all the translations if the ETag does not match" do
        get "/test/published_blurbs"
        
        last_response.should be_ok
        JSON.parse(last_response.body).should == {
          "application.home.title" => "Home Page",
          "application.home.body" => "This is the home page."
        }
      end
      
      it "returns a status code of 302, with an empty body, if the ETag does match" do
        header "If-None-Match", redis.get("projects:test:published_blurbs_etag")
        get "/test/published_blurbs"

        last_response.status.should eq 304
        last_response.body.should be_empty
      end
      
      it "does not load the translation list if the ETag matches" do
        blurbs = stub(:bytesize => 0, :etag => "foo")
        TextTractor::ApiServer::BlurbList.should_receive(:new).and_return(blurbs)
        blurbs.should_not_receive(:each)
        
        header "If-None-Match", "foo"
        get "/test/published_blurbs"

        last_response.status.should eq 304
        last_response.body.should be_empty
      end

      it "sets the ETag to be set" do
        get "/test/published_blurbs"

        last_response.headers["ETag"].should_not be_nil
        last_response.headers["ETag"].should == redis.get("projects:test:published_blurbs_etag")
      end
    end

    context "when the project does not exist" do
      it "returns a 404 error code" do
        get "/test/draft_blurbs"

        last_response.status.should eq 404
      end
    end
  end

  describe "publishing blurbs" do
    context "when the project does exist" do
      before(:each) do
        post "/", :name => "Test Project", :api_key => "test"
        post "/test/draft_blurbs", {
          "application.home.title" => "A Title"
        }.to_json
      end

      it "has a 200 response code" do
        post "/test/deploys"
        last_response.status.should eq 200
      end

      it "marks the draft blurbs as published" do
        get "/test/published_blurbs"
        JSON.parse(last_response.body).should be_empty

        post "/test/deploys"
        get "/test/published_blurbs"
        JSON.parse(last_response.body).should == {
          "application.home.title" => "A Title"
        }
      end
    end

    context "when the project does not exist" do
      it "returns a 404 error code" do
        post "/test/publish"
        last_response.status.should eq 404
      end
    end
  end
end
