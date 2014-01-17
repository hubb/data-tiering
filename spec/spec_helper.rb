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

class CreateProperties < ActiveRecord::Migration
  def self.up
    create_table :properties do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :properties
  end
end

class CreateRates < ActiveRecord::Migration
  def self.up
    create_table :rates do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end

  def self.down
    drop_table :rates
  end
end

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

    CreateProperties.up
    CreateRates.up

    properties_model_migration = Class.new(ActiveRecord::Migration).extend(DataTiering::ModelMigration)
    properties_model_migration.table_name = 'properties'
    properties_model_migration.up

    rates_model_migration = Class.new(ActiveRecord::Migration).extend(DataTiering::ModelMigration)
    rates_model_migration.table_name = 'rates'
    rates_model_migration.up
  end
end
