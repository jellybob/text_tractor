module TextTractor
  class Phrase
    attr_reader :translations, :project
    
    def initialize(project, phrase = {})
      @project = project
      @translations = {}
      
      phrase.each do |locale, value|
        @translations[locale.to_s] = Translation.new(self, locale.to_s, value["text"], value["translated_at"] && Time.parse(value["translated_at"]))
      end
    end
    
    def default_locale
      project.default_locale
    end
    
    def [](locale)
      @translations[locale.to_s] ||= Translation.new(self, locale.to_s)
      @translations[locale.to_s]
    end

    def []=(locale, value)
      self[locale.to_s].text = value
    end
    
    def to_hash
      hash = {}

      @translations.each do |locale, value|
        hash[locale.to_s] = { "text" => value.text, "translated_at" => value.translated_at ? value.translated_at.to_s : nil }
      end
      
      hash
    end

    class Translation
      attr_accessor :phrase, :locale, :text, :translated_at
      
      def initialize(phrase, locale, text = nil, translated_at = nil, phrase_created_at = nil)
        @phrase = phrase
        @locale = locale
        @text = text
        @translated_at = translated_at
        @created_at = phrase_created_at
      end
      
      def text=(value)
        @text = value
        @translated_at = Time.now
      end

      def to_s
        text || ""
      end
      
      def default_locale
        phrase.default_locale
      end

      def state
        return :untranslated if translated_at.nil?
        return :translated if phrase[default_locale].translated_at.nil?
        translated_at >= phrase[default_locale].translated_at ? :translated : :stale
      end
    end
  end
end
