# This code is licensed under the MIT License
# author https://github.com/padrino/padrino-framework
module Library
  module Flash
    class << self
      def registered(app)
        app.helpers Helpers
        app.after do
          session[:_flash] = @_flash.next if @_flash
        end
      end
    end
    class Storage
      include Enumerable
      def initialize(session=nil)
        @_now  = session || {}
        @_next = {}
      end
      def now
        @_now
      end
      def next
        @_next
      end
      def [](type)
        @_now[type]
      end
      def []=(type, message)
        @_next[type] = message
      end
      def delete(type)
        @_now.delete(type)
        self
      end
      def keys
        @_now.keys
      end
      def key?(type)
        @_now.key?(type)
      end
      def each(&block)
        @_now.each(&block)
      end
      def replace(hash)
        @_now.replace(hash)
        self
      end
      def update(hash)
        @_now.update(hash)
        self
      end
      alias_method :merge!, :update
      def sweep
        @_now.replace(@_next)
        @_next = {}
        self
      end
      def keep(key = nil)
        if key
          @_next[key] = @_now[key]
        else
          @_next.merge!(@_now)
        end
        self
      end
      def discard(key = nil)
        if key
          @_next.delete(key)
        else
          @_next = {}
        end
        self
      end
      def clear
        @_now.clear
      end
      def empty?
        @_now.empty?
      end
      def to_hash
        @_now.dup
      end
      def length
        @_now.length
      end
      alias_method :size, :length
      def to_s
        @_now.to_s
      end
      def error=(message)
        self[:error] = message
      end
      def error
        self[:error]
      end
      def notice=(message)
        self[:notice] = message
      end
      def notice
        self[:notice]
      end
      def success=(message)
        self[:success] = message
      end
      def success
        self[:success]
      end
    end
    module Helpers
      def redirect(url, *args)
        flashes = args.last.is_a?(Hash) ? args.pop : {}
        flashes.each do |type, message|
          message = I18n.translate(message) if message.is_a?(Symbol) && defined?(I18n)
          flash[type] = message
        end
        super(url, args)
      end
      def flash
        @_flash ||= Storage.new(env['rack.session'] ? session[:_flash] : {})
      end
    end
  end
end