# encoding: UTF-8

require 'pry'
require 'pry-nav'

require 'data_tiering'
require 'active_record'
require 'active_support'
require 'timecop'

require 'rspec'
require 'support/models'
require 'support/fake_cache'

require 'database_cleaner'

require 'logger'
ActiveRecord::Base.logger = Logger.new('/dev/null')

database_config = YAML.load(File.read('spec/database.yml'))['test']

ActiveRecord::Migration.verbose = false

DataTiering.configure do |config|
  config.env = 'test'
  config.cache = FakeCache.new
end

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = :documentation

  config.before(:suite) do
    Time.zone = 'London'

    ActiveRecord::Base.establish_connection database_config.merge('database' => nil)
    ActiveRecord::Base.connection.drop_database database_config['database'] rescue nil
    ActiveRecord::Base.connection.create_database database_config['database']
    ActiveRecord::Base.establish_connection database_config

    run_migrations

    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    ActiveRecord::Base.connection.drop_database database_config['database'] rescue nil
  end

  config.before(:each) do
    DatabaseCleaner.start
    DataTiering.configuration.cache.clear
  end

  config.after(:each) do
    DatabaseCleaner.clean rescue Mysql2::Error # migration specs mess up tables
  end

  def run_migrations
    setup_migration = Class.new(ActiveRecord::Migration).extend(DataTiering::SetupMigration)
    setup_migration.up
    # ActiveRecord::Migrator.migrate File.expand_path('../support/migrations/', __FILE__)
    # ActiveRecord::Migrator.migrate File.expand_path('../../lib/generators/data_tiering/migrations/', __FILE__)
  end
end
