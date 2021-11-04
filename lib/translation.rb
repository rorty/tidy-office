module Library
  module Translation
    module Helpers
      def translate(*args)
        ::I18n.translate(*args)
      end
      alias :t :translate
      def localize(*args)
        ::I18n.localize(*args)
      end
      alias :l :localize
    end
    def self.registered(app)
      app.helpers Helpers
      ::I18n.load_path << app.locale_path
    end
  end
end
