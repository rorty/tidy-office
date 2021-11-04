RACK_ENV = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)
APP_ROOT = File.expand_path('../..', __FILE__) unless defined?(APP_ROOT)

require 'bundler/setup'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/output_safety'
require 'active_support/core_ext/string/inflections'
require "active_support/core_ext/hash/indifferent_access"
require 'active_support/core_ext/object/try'
require 'sequel'
require 'sequel/extensions/pagination'
require 'sinatra/base'
require 'sinatra/namespace'
require "sinatra/reloader" 
require "sinatra/config_file" 

require 'i18n'
require 'haml'
require 'tiny_tds'
require "prawn"
require "prawn-svg"
require 'barby'
require 'barby/barcode/code_128'
require 'chunky_png'
require 'barby/outputter/png_outputter'
require 'barby/outputter/prawn_outputter'
require "prawn/measurement_extensions"

require 'tilt'
require 'tilt/template'

Bundler.require(:default, RACK_ENV)
require_relative '../config/database'
require_relative '../config/pluralization'

require_relative '../helpers/application_helpers'

require_relative '../lib/flash'
require_relative '../lib/translation'
require_relative '../lib/pdf_label'


require_relative '../models/cartridge_model'
require_relative '../models/manufacturer'
require_relative '../models/cartridge'
require_relative '../models/place'
require_relative '../models/device_model'
require_relative '../models/device_type'
require_relative '../models/cartridge_type'
require_relative '../models/devices'
require_relative '../models/events'
require_relative '../models/contract'
require_relative '../models/cartridge_note'
require_relative '../models/device_note'



module CartridgeManagement
  class Application < Sinatra::Base
    configure do
      set :root,  APP_ROOT
      set :logging, false
      set :server, :puma
      set :locale_path, proc { Dir.glob File.join(root, 'config/locales/**/*.{rb,yml}') }
      set :locales,     proc { File.join(APP_ROOT, 'config/locales/ru.yml') }
      set :views,       proc { File.join(root, 'views') }
      set :locale, :ru
      set :uri_root,      '/'
      set :public_folder, proc { File.join(root, 'public') }
      set :images_path,   proc { File.join(public_folder, 'images') }
      set :sessions, true
      set :method_override, true
      set :prawn, { :left_margin => 10.mm, :top_margin => 10.mm, :bottom_margin => 10.mm, :margin => 10.mm, :page_size => "A4" }
      register Sinatra::ConfigFile
      register Sinatra::Namespace
      register Sinatra::RespondWith
      register Library::Flash
      register Library::Prawn
      register Library::Translation
      register Sequel::Dataset::Pagination
      helpers Library::Helpers::ApplicationHelpers
      helpers Sinatra::ContentFor
      config_file File.join(root, 'config/config.yml')
    end   
    configure :development do
      register Sinatra::Reloader
      Dir.glob(File.join(APP_ROOT, 'apps', '**', '*.rb')).each { |t| also_reload t }
      Dir.glob(File.join(APP_ROOT, 'helpers', '*.rb')).each { |t| also_reload t }
      Dir.glob(File.join(APP_ROOT, 'lib', '**', '*.rb')).each { |t| also_reload t }
      Dir.glob(File.join(APP_ROOT, 'models', '*.rb')).each { |t| also_reload t }
    end
  end
end

require_relative '../apps/app'

I18n.default_locale = :ru
I18n.enforce_available_locales = false