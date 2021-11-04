RACK_ENV = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)
APP_ROOT = File.expand_path(__FILE__) unless defined?(APP_ROOT)

require 'bundler/setup'
require 'sequel'
require 'logger'
require_relative 'config/database'
require 'rake'
require 'rake/dsl_definition'
require 'thor'

include Rake::DSL

def shell
  @_shell ||= Thor::Base.shell.new
end

module Tasks
  namespace :sq do
    namespace :migrate do
      desc "Perform automigration (reset your db data)"
      task :auto do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate", :target => 0
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate"
        puts "<= sq:migrate:auto executed"
      end

      desc "Perform migration up/down to MIGRATION_VERSION"
      task :to, [:version] => :skeleton do |t, args|
        version = (args[:version] || env_migration_version).to_s.strip
        ::Sequel.extension :migration
        fail "No MIGRATION_VERSION was provided" if version.empty?
        ::Sequel::Migrator.apply(Sequel::Model.db, "db/migrate", version.to_i)
        puts "<= sq:migrate:to[#{version}] executed"
      end

      desc "Perform migration up to latest migration available"
      task :up do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate"
        puts "<= sq:migrate:up executed"
      end

      desc "Perform migration down (erase all data)"
      task :down do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate", :target => 0
        puts "<= sq:migrate:down executed"
      end
    end

    desc "Perform migration up to latest migration available"
    task :migrate => 'sq:migrate:up'
  end
end