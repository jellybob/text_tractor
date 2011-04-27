require 'spec_helper'

describe "working with a project", :type => :request do
  before(:each) do
    @project = TextTractor::Projects.create(name: "Test Project", api_key: "test")

    login
  end

  context "when the project has had no blurbs added to it" do
    it "displays some advice on adding it to your project, including the API key" do
      visit '/projects/test'

      page.should have_content %q{config.api_key = "test"}
      page.should have_content %q{config.host = "example.host"}
      page.should have_content %q{config.port = 8000}
      page.should have_content %q{config.secure = false}
    end
  end

  context "when the project has had some blurbs added to it" do
    before(:each) do
      @project.update_draft_blurbs({
        "en.application.home.title" => "Home Page"
      })
    end

    it "displays a list of all the known blurbs on the project index" do
      visit '/projects/test'
      page.should have_content "Application / Home / Title"
      page.should have_content "Home Page"
    end

    it "updates the blurb content on a POST" do
      post "/projects/test/en/application/home/title", :blurb => "Test"

      @project.draft_blurbs["en.application.home.title"].should == "Test"
    end
  end
end
