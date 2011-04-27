require 'spec_helper'

describe TextTractor::Project do
  it { should_not be_nil }
  it { should respond_to :name }
  it { should respond_to :api_key }
  it { should respond_to :default_locale }
  it { should respond_to :users }

  it "defaults the api_key to a random key" do
    TextTractor::Projects.stub(:random_key).and_return("4") # Chosen by fair dice roll.
    subject.api_key.should == "4"
  end

  it "defaults the locale to 'en'" do
    subject.default_locale.should == "en"
  end

  it "defaults the users to an empty array" do
    subject.users.should == []
  end

  specify { should respond_to(:update_draft_blurbs) }
  describe "updating the draft blurbs" do
    before(:each) do
      @project = TextTractor::Projects.create(name: "Test", api_key: "test")
      @project.update_draft_blurbs(
        "en.application.home.title" => "Home Page",
        "en.application.home.body" => "This is the home page.",
      )
    end
    
    it "saves the new translations" do
      JSON.parse(redis.get("projects:test:draft_blurbs:application.home.title")).should == {
        "en" => "Home Page"
      }

      JSON.parse(redis.get("projects:test:draft_blurbs:application.home.body")).should == {
        "en" => "This is the home page."
      }
    end
    
    it "correctly retains quotes" do
      @project.update_draft_blurbs(
        "en.application.home.quoted" => %q{"I would like to test quoting." said Jon.}
      )
            
      JSON.parse(redis.get("projects:test:draft_blurbs:application.home.quoted")).should == {
        "en" => %q{"I would like to test quoting." said Jon.}
      }
    end

    it "generates a new ETag if the translations have changed" do
      redis.get("projects:test:draft_blurbs_etag").should_not be_nil
    end

    it "does not replace the content of existing translations by default" do
      @project.update_draft_blurbs(
        "en.application.home.title" => "A different title"
      )

      JSON.parse(redis.get("projects:test:draft_blurbs:application.home.title")).should == {
        "en" => "Home Page" 
      }
    end

    it "replaces the content of existing translations if :overwrite is set" do
      @project.update_draft_blurbs({
        "en.application.home.title" => "A different title"
      }, :overwrite => true)
      
      JSON.parse(redis.get("projects:test:draft_blurbs:application.home.title")).should == {
        "en" => "A different title" 
      }
    end

    it "does not generate a new ETag if the translations did not change" do
      previous_etag = redis.get("projects:test:draft_blurbs_etag")
      
      @project.update_draft_blurbs(
        "en.application.home.title" => "A different title"
      )
      redis.get("projects:test:draft_blurbs_etag").should == previous_etag
    end
  end
  
  specify { should respond_to(:draft_blurbs) }
  describe "getting the draft blurbs for a project" do
    context "when the project exists" do
      before(:each) do
        @project = TextTractor::Projects.create(name: "Test Project", api_key: "test")
        @project.update_draft_blurbs({
          "en.application.home.title" => "Home Page",
          "en.application.home.body" => "This is the home page."
        })
      end

      subject { @project.draft_blurbs }
      
      it "returns all the translations" do
        subject.should == {
          "en.application.home.title" => "Home Page",
          "en.application.home.body" => "This is the home page."
        }
      end
    end
  end
end

describe TextTractor::Projects do
  specify { TextTractor::Projects.should respond_to(:create) }
   
  describe "creating a new project" do
    context "when succesful" do
      before(:each) { @project = TextTractor::Projects.create name: "Test Project", api_key: "49032804328090f8sd0fas0jds", users: [ "jon@blankpad.net", "bob@example.org" ] }
      subject { @project }
       
      it "returns the details as a project instance" do
        subject.should be_instance_of TextTractor::Project

        subject.name.should == "Test Project"
        subject.api_key.should == "49032804328090f8sd0fas0jds"
      end
      
      it "saves the projects details for later use" do
        TextTractor.redis.get("projects:49032804328090f8sd0fas0jds").should == subject.to_json
      end
      
      it "adds the API key to the project index" do
        TextTractor.redis.sismember("projects", "49032804328090f8sd0fas0jds").should be_true
      end

      it "places the project name in a set for quick reference" do
        TextTractor.redis.sismember("project_names", "Test Project").should be_true
      end

      it "assigns any provided users to the project" do
        TextTractor.redis.sismember("project_users:49032804328090f8sd0fas0jds", "bob@example.org").should be_true
        TextTractor.redis.sismember("project_users:49032804328090f8sd0fas0jds", "jon@blankpad.net").should be_true
      end
    end

    it "rejects a project with the same name as an existing project" do
      TextTractor::Projects.create name: "Test Project"
      
      lambda { TextTractor::Projects.create name: "Test Project" }.should raise_error(TextTractor::Projects::DuplicateProjectName)
    end
  end

  describe "getting an existing project" do
    it "returns the project on success" do
      TextTractor::Projects.create name: "Test Project", api_key: "test"

      project = TextTractor::Projects.get("test")
      project.should be_instance_of TextTractor::Project
      project.name.should == "Test Project"
      project.api_key.should == "test"
    end

    it "returns nil if the project did not exist" do
      TextTractor::Projects.get("test").should be_nil
    end
  end

  describe "listing projects for a user" do
    before(:each) do
      TextTractor::Projects.create(name: "Assigned Project", users: [ "example" ])
      TextTractor::Projects.create(name: "Unassigned Project")
    end
    
    let(:user) do
      { "username" => "example",
        "superuser" => false }
    end
    
    specify { TextTractor::Projects.should respond_to(:for_user) }
    
    it "returns all projects if the user is a superuser" do
      user["superuser"] = true
      projects = TextTractor::Projects.for_user(user)
      
      projects.should have(2).projects
      projects.first["name"].should eq "Assigned Project"
      projects.last["name"].should eq "Unassigned Project"
    end

    it "returns only projects the user has been added to for standard users" do
      user["superuser"] = false
      projects = TextTractor::Projects.for_user(user)
      
      projects.should have(1).project
      projects.first["name"].should eq "Assigned Project"
    end
  end

  specify { TextTractor::Projects.should respond_to(:authorised?) }
  describe "checking authorisation for a project" do
    before(:each) do
      TextTractor::Projects.create(name: "Test", api_key: "test", users: [ "bob@example.org" ])
    end

    it "returns true if the user is a super user" do
      TextTractor::Projects.authorised?({ "superuser" => true }, "test")
    end

    it "returns true if the user is in the list of assigned users for the project" do
      TextTractor::Projects.authorised?({ "superuser" => false, "username" => "bob@example.org" }, "test")
    end
    
    it "returns false if the user is not in the list of assigned users for the project" do
      TextTractor::Projects.authorised?({ "superuser" => false, "username" => "frank@example.org" }, "test")
    end
  end
  
  specify { TextTractor::Projects.should respond_to(:update_datastore) }
  describe "migrating a data store to the current version" do
    before(:each) do
      TextTractor::Projects.create(name: "Test", api_key: "test")
      
      redis.set("projects:test:draft_blurbs:en.application.home.title", "Home page")
      redis.sadd("projects:test:draft_blurb_keys", "en.application.home.title")
      redis.set("projects:test:draft_blurbs:cy.application.home.title", "Hafan")
      redis.sadd("projects:test:draft_blurb_keys", "cy.application.home.title")
      redis.set "projects:test:draft_blurbs_etag", "old_etag"

      TextTractor::Projects.update_datastore
    end

    it "updates the ETag" do
      redis.get("projects:test:draft_blurbs_etag").should_not == "old_etag"
    end

    it "places all translations of a phrase under one key" do
      redis.sismember("projects:test:draft_blurb_keys", "application.home.title").should be_true
      redis.get("projects:test:draft_blurbs:application.home.title").should == {
        "en" => "Home page",
        "cy" => "Hafan"
      }.to_json
    end

    it "removes the old blurbs" do
      redis.sismember("projects:test:draft_blurb_keys", "en.application.home.title").should_not be_true
      redis.sismember("projects:test:draft_blurb_keys", "cy.application.home.title").should_not be_true

      redis.get("projects:test:draft_blurbs:en.application.home.title").should be_nil
      redis.get("projects:test:draft_blurbs:cy.application.home.title").should be_nil
    end
  end
end
