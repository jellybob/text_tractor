require 'spec_helper'

describe Copycat::Projects do
  specify { Copycat::Projects.should respond_to(:create) }
   
  describe "creating a new project" do
    it "on success it creates the project, and returns the details provided" do
      result = Copycat::Projects.create name: "Test Project", api_key: "49032804328090f8sd0fas0jds"
      result.should == {
        "name" => "Test Project",
        "api_key" => "49032804328090f8sd0fas0jds"
      }

      JSON.parse(Copycat.redis.get("projects:49032804328090f8sd0fas0jds")).should == result
      Copycat.redis.sismember("project_names", "Test Project").should be_true
      Copycat.redis.sismember("projects", "49032804328090f8sd0fas0jds").should be_true
    end

    it "generates a random API key if one hasn't been specified" do
      result = Copycat::Projects.create name: "Test Project"
      result.should have_key("api_key")
      result["api_key"].should_not be_nil
    end

    it "rejects a project with the same name as an existing project" do
      Copycat::Projects.create name: "Test Project"
      
      lambda { Copycat::Projects.create name: "Test Project" }.should raise_error(Copycat::Projects::DuplicateProjectName)
    end

    it "assigns any provided users to the project" do
      Copycat::Projects.create name: "Test Project", api_key: "test", users: [ "jon@blankpad.net", "bob@example.org" ]

      Copycat.redis.sismember("project_users:test", "bob@example.org").should be_true
      Copycat.redis.sismember("project_users:test", "jon@blankpad.net").should be_true
    end
  end

  describe "getting an existing project" do
    it "returns the project on success" do
      Copycat::Projects.create name: "Test Project", api_key: "test"

      project = Copycat::Projects.get("test")
      project.should_not be_nil
      project["name"].should == "Test Project"
      project["api_key"].should == "test"
    end

    it "returns nil if the project did not exist" do
      Copycat::Projects.get("test").should be_nil
    end
  end

  describe "listing projects for a user" do
    before(:each) do
      Copycat::Projects.create(name: "Assigned Project", users: [ "example" ])
      Copycat::Projects.create(name: "Unassigned Project")
    end
    
    let(:user) do
      { "username" => "example",
        "superuser" => false }
    end
    
    specify { Copycat::Projects.should respond_to(:for_user) }
    
    it "returns all projects if the user is a superuser" do
      user["superuser"] = true
      projects = Copycat::Projects.for_user(user)
      
      projects.should have(2).projects
      projects.first["name"].should eq "Assigned Project"
      projects.last["name"].should eq "Unassigned Project"
    end

    it "returns only projects the user has been added to for standard users" do
      user["superuser"] = false
      projects = Copycat::Projects.for_user(user)
      
      projects.should have(1).project
      projects.first["name"].should eq "Assigned Project"
    end
  end

  specify { Copycat::Projects.should respond_to(:authorised?) }
  describe "checking authorisation for a project" do
    before(:each) do
      Copycat::Projects.create(name: "Test", api_key: "test", users: [ "bob@example.org" ])
    end

    it "returns true if the user is a super user" do
      Copycat::Projects.authorised?({ "superuser" => true }, "test")
    end

    it "returns true if the user is in the list of assigned users for the project" do
      Copycat::Projects.authorised?({ "superuser" => false, "username" => "bob@example.org" }, "test")
    end
    
    it "returns false if the user is not in the list of assigned users for the project" do
      Copycat::Projects.authorised?({ "superuser" => false, "username" => "frank@example.org" }, "test")
    end
  end
end
