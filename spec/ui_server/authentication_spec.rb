require 'spec_helper'

describe "authentication", :type => :request do
  it "rejects the request if no authentication was provided" do
    get "/"
    last_response.status.should eq 401
  end
  
  it "allows access if logging in with the default credentials" do
    Copycat.configuration.default_username = "admin"
    Copycat.configuration.default_password = "password"
    
    basic_authorize "admin", "password"
    
    get "/"
    last_response.status.should eq 200
  end

  describe "managing users" do
    it "denies access to user who is not a superuser" do
      create_user "bob@example.org", "p@ssw0rd"
      login "bob@example.org", "p@ssw0rd"

      visit "/"
      page.should_not have_content "Users"

      visit "/users"
      Capybara.current_session.status_code.should eq 403
    end

    it "allows access to the default user" do
      login

      visit "/"
      click_link "Users"
      
      page.should have_content "User Management"
      page.should have_content "Default User"
    end

    it "allows the creation of a new user" do
      login

      visit "/users"

      page.should have_content "Create a User"

      fill_in "Username", :with => "bob@example.org"
      fill_in "Name", :with => "Bob Hoskins"
      fill_in "Password", :with => "p@ssw0rd"
      click_button "Create User"
      
      page.should have_content "Bob Hoskins"

      login "bob@example.org", "p@ssw0rd"
      visit "/"
      Capybara.current_session.status_code.should eq 200
    end
  end
end
