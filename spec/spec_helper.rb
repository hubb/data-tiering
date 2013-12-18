# encoding: UTF-8

require 'pry'
require 'pry-nav'

require 'active_record'
require 'active_support'
require 'timecop'

require 'rspec'
require 'data_tiering'
require 'data_tiering/sync'
require 'support/models'

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = 2

RSpec.configure do |config|

  config.color_enabled = true
  config.formatter     = :documentation

  config.before(:suite) do
    setup_database
  end

  config.after(:suite) do
    `mysql -u root -e "drop database data_tiering_test"`
  end

  def setup_database
    `mysql -u root -e "create database data_tiering_test"`

    ActiveRecord::Base.establish_connection(
      :adapter  =>  'mysql2',
      :database =>  "data_tiering_test"
    )

    m = ActiveRecord::Migration
    m.verbose = true
    m.create_table :properties do |t|
      t.string :name
      t.text :description

      t.timestamps
      t.datetime :row_touched_at
    end
    m.create_table :properties_secondary_0 do |t|
      t.string :name
      t.text :description

      t.timestamps
      t.datetime :row_touched_at
    end

    m.create_table :data_tiering_sync_logs do |t|
      t.string :table_name
      t.datetime :started_at
      t.datetime :finished_at
    end

    m.create_table :data_tiering_switches do |t|
      t.integer :current_active_number
      t.timestamps
    end
  end


  class FakeCache
    def initialize
      @values = {}
    end

    def read(key)
      @values[key]
    end

    def write(key, value)
      @values[key] = value
    end

    def clear
      @values = {}
    end
  end

  def cache
    @_cache ||= FakeCache.new
  end

end
