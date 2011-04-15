require 'spec_helper'

describe "project management" do
  context "as a superuser" do
    before(:each) do
      create_superuser "jim@example.org", "password"
      login_for_capybara "jim@example.org", "password"
    end
    
    pending "it allows access to the project list"

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

    pending "it allows access to a project the user has been explicitly added to"
    pending "it allows access to a project the user has not been added to"
  end

  context "as a normal user" do
    before(:each) do
      create_user "bob@example.org", "password"
      login_for_capybara "bob@example.org", "password"
    end

    pending "denies access to create a new project"
    pending "it lists only the projects the user has been added to"
    pending "allows access to a projec the user has been added to"
    pending "it denies access to project the user has not been added to"
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
