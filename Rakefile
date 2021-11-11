require 'bundler/setup'
require 'rake'
require 'rake/dsl_definition'
require 'thor'
require File.expand_path('../config/boot.rb', __FILE__)
include Rake::DSL

def shell
  @_shell ||= Thor::Base.shell.new
end

module Tasks
  namespace :db do
    namespace :migrate do
      desc "Perform automigration (reset your db data)"
      task :auto do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate", :target => 0
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate"
        puts "<= db:migrate:auto executed"
      end

      desc "Perform migration up/down to MIGRATION_VERSION"
      task :to, [:version] => :skeleton do |t, args|
        version = (args[:version] || env_migration_version).to_s.strip
        ::Sequel.extension :migration
        fail "No MIGRATION_VERSION was provided" if version.empty?
        ::Sequel::Migrator.apply(Sequel::Model.db, "db/migrate", version.to_i)
        puts "<= db:migrate:to[#{version}] executed"
      end

      desc "Perform migration up to latest migration available"
      task :up do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate"
        puts "<= db:migrate:up executed"
      end

      desc "Perform migration down (erase all data)"
      task :down do
        ::Sequel.extension :migration
        ::Sequel::Migrator.run Sequel::Model.db, "db/migrate", :target => 0
        puts "<= db:migrate:down executed"
      end
    end

    desc "Perform migration up to latest migration available"
    task :migrate => 'db:migrate:up'
  end
end