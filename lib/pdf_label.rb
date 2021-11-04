module Library
  module Prawn
    module Helpers
      def prawn(template, options = {}, locals = {}, &block)
        render(:prawn, template, options, locals, &block)
      end
    end
    def self.registered(app)
      app.helpers Prawn::Helpers
    end
  end
end
