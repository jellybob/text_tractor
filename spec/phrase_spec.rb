require 'spec_helper'

describe TextTractor::Phrase do
  let(:project) { TextTractor::Project.new(default_locale: "en", name: "Test Project", api_key: "test") }
  subject do
    TextTractor::Phrase.new(project, {
      en: { text: "An example", translated_at: Time.new(2011, 01, 03, 00, 32, 00).to_s }, 
      cy: { text: "An example in Welsh", translated_at: Time.new(2011, 01, 03, 00, 12, 00).to_s }
    })
  end
  
  it "should set the phrase's project" do
    subject.project.should == project
  end

  describe "converting to a hash for saving" do
    specify do
      subject.to_hash.should == {
        "en" =>  { "text" => "An example", "translated_at" => Time.new(2011, 01, 03, 00, 32, 00).to_s }, 
        "cy" =>  { "text" => "An example in Welsh", "translated_at" => Time.new(2011, 01, 03, 00, 12, 00).to_s }
      }
    end
  end

  it { should respond_to(:[]) }
  it { should respond_to(:[]=) }
  
  describe "accessing the individual translations" do
    it "allows direct access to the translated string" do
      subject["en"].to_s.should == "An example"
      subject["cy"].to_s.should == "An example in Welsh"
    end

    it "allows the translation of a phrase to be set" do
      subject["cy"] = "A new translation"
      subject["cy"].to_s.should == "A new translation"
    end

    it "returns an empty string when the translation has not been made" do
      subject["de"].to_s.should == ""
      subject["de"].translated_at.should be_nil
    end
  end
  
  describe "setting a translation" do
    before(:each) do
      Time.stub(:now).and_return(Time.new(2011, 04, 11))
    end

    it "sets the translation time" do
      subject["de"] = "Hello!"
      subject["de"].translated_at.should == Time.new(2011, 04, 11)
    end
  end

  describe "translaion states" do
    it "is considered translated if the default locale was translated before this translation" do
      subject["cy"].translated_at = subject["en"].translated_at + 40
      subject["cy"].state.should == :translated
    end

    it "is considered untranslated if no translation time is set" do
      subject["de"].state.should == :untranslated
    end

    it "is considered stale if the translation time is earlier then that on the default locale" do
      subject["cy"].translated_at = subject["en"].translated_at - 40
      subject["cy"].state.should == :stale
    end
  end
end
