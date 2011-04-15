require 'spec_helper'

describe "working with a project", :type => :request do
  before(:each) do
    Copycat::Projects.create(name: "Test Project", api_key: "test")

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
end
