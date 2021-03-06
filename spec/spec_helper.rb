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


DataTiering.configure do |config|
  config.env = 'test'
  config.cache = FakeCache.new
end

RSpec.configure do |config|

  config.color_enabled = true
  config.formatter     = :documentation

  config.before(:suite) do
    Time.zone = 'London'
    setup_database
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
    DataTiering.configuration.cache.clear
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end


  config.after(:suite) do
    `mysql -u root -e "drop database data_tiering_test"`
  end

  def setup_database
    `mysql -u root -e "create database data_tiering_test"`

    ActiveRecord::Base.establish_connection(
      :adapter  =>  'mysql2',
      :database =>  'data_tiering_test'
    )

    migration = ActiveRecord::Migration
    migration.verbose = ENV.fetch('VERBOSE', false)
    migration.create_table :properties do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_timestamp(migration, :properties, :row_touched_at)

    migration.create_table :rates do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
    add_timestamp(migration, :rates, :row_touched_at)

    migration.create_table :data_tiering_sync_logs do |t|
      t.string :table_name
      t.datetime :started_at
      t.datetime :finished_at
    end

    migration.create_table :data_tiering_switches do |t|
      t.integer :current_active_number
      t.timestamps
    end
  end

  def add_timestamp(migration, table_name, column_name)
    migration.execute <<-SQL
      ALTER TABLE #{table_name}
      ADD #{column_name} TIMESTAMP
      DEFAULT CURRENT_TIMESTAMP
      ON UPDATE CURRENT_TIMESTAMP
    SQL
    migration.update <<-SQL
      UPDATE #{table_name}
      SET #{column_name} = '2000-01-01 00:00:01'
    SQL
  end
end
