require 'spec_helper'

describe "project management" do
  context "as a superuser" do
    before(:each) do
      create_superuser "jim@example.org", "password"
      login "jim@example.org", "password"
    end
    
    it "it lists all projects" do
      Copycat::Projects.create(name: "Test Project")
      Copycat::Projects.create(name: "User Specified Project", users: [ "jim@example.org" ])

      visit '/'
      page.should have_content "Test Project"
      page.should have_content "User Specified Project"
    end
    
    it "it allows a new project to be created" do
      visit '/'
      page.should have_content "Create a Project"

      click_link "Create a Project"

      fill_in "Project Name", :with => "Example Project"
      check "jim@example.org"
      click_button "Create Project"

      page.should have_content "Example Project"
    end

    it "allows access to a project the user has been explicitly added to" do
      project = Copycat::Projects.create(name: "User Specified Project", users: [ "jim@example.org" ])
      
      get "/projects/#{project["api_key"]}"
      last_response.status.should eq 200
    end

    it "allows access to a project the user has not been added to" do
      project = Copycat::Projects.create(name: "User Specified Project")
      
      get "/projects/#{project["api_key"]}"
      last_response.status.should eq 200
    end
  end

  context "as a normal user" do
    before(:each) do
      Copycat::Projects.create(name: "Test Project", api_key: "test")
      Copycat::Projects.create(name: "User Specified Project", api_key: "user", users: [ "bob@example.org" ])
      
      create_user "bob@example.org", "password"
      login "bob@example.org", "password"
    end

    it "denies access to create a new project" do
      visit '/'
      page.should_not have_content "Create a Project"

      get '/projects/new'
      last_response.status.should eq 403
    end
    
    it "lists only the projects the user has been added to" do
      visit '/'
      page.should have_content "User Specified Project"
      page.should_not have_content "Test Project"
    end

    it "allows access to a project the user has been added to" do
      get '/projects/user'
      last_response.status.should eq 200
    end

    it "denies access to project the user has not been added to" do
      get '/projects/test'
      last_response.status.should eq 403
    end
  end

  context "when not logged in" do
    it "denies access to the project list" do
      get "/"
      last_response.status.should eq 401
    end

    it "denies access to create a new project" do
      post "/"
      last_response.status.should eq 401
    end

    it "denies access to view a project" do
      get "/projects/test"
      last_response.status.should eq 401
    end
  end
end
