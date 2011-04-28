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
        "en.application.home.title" => "Home Page",
        "cy.application.home.title" => "Dafan",
        "en.application.home.body" => "This is the home page."
      })
    end
    
    it "allows the locale to be selected" do
      visit '/projects/test'
      within "ul#locales" do
        page.should have_content "cy"
        page.should have_content "en"
      end

      click_link "cy"
      page.should have_content "Test Project (cy)"
    end

    it "displays a list of all the known blurbs in the default locale on the project index" do
      visit '/projects/test'
      page.should have_content "Application / Home / Title"
      page.should have_content "Home Page"
    end
    
    it "displays a list of all the known blurbs in the selected locale if one was set" do
      visit '/projects/test/cy'
      page.should have_content "Application / Home / Title"
      page.should have_content "Dafan"
    end
    
    it "displays the original version of each blurb if the default locale is not selected" do
      visit '/projects/test/cy'
      find('dd[data-key="application.home.title"] p.original').should have_content "Home Page"
    end

    it "displays 'Click to add a translation' if no translation has been provided" do
      visit '/projects/test/cy'
      find('dd[data-key="application.home.body"] p.translation').should have_content "Click to add a translation"
    end

    it "updates the blurb content on a POST" do
      post "/projects/test/en/application/home/title", :blurb => "Test"

      @project.draft_blurbs["en.application.home.title"].should == "Test"
    end

    it "displays the form for editing on a GET" do
      visit "/projects/test/en/application/home/title"
      
      page.find("form")["action"].should == "/projects/test/en/application/home/title"
      within("textarea[name='blurb']") do
        page.should have_content "Home Page"
      end
    end
  end
end
