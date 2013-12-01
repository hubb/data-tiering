# encoding: UTF-8

require 'pry'
require 'pry-nav'

require 'rspec'
require 'rspec_candy/all'
require 'data_tiering'
require 'data_tiering/sync'

require 'timecop'
require 'active_record'

SPEC_CONNECTIONS = {
  :mysql => {
    :adapter  => 'mysql2',
    :database => 'data_tiering_test',
    :encoding => 'utf8',
    :username => 'root',
    :host     => 'localhost'
  },
  :postgresql => {
    :adapter      => 'postgresql',
    :database     => 'data_tiering_test',
    :encoding     => 'unicode',
    :username     => 'root',
    :host         => 'localhost',
    :port         => 5432,
    :pool         => 5,
    :min_messages => 'warning'
  },
  :sqlite => {
    :adapter =>  'sqlite3',
    :database =>  File.join(File.expand_path("..", __FILE__), "data_tiering_test.sqlite")
  }
}

ActiveRecord::Base.establish_connection SPEC_CONNECTIONS[(ENV['TEST_DATABASE'] || :mysql).to_sym]

RSpec.configure do |config|

  # Allow constant stubbing
  def with_constants(constants, &block)
    saved_constants = {}
    constants.each do |constant, val|
      saved_constants[constant] = const_get(constant) if const_defined?(constant)
      Kernel::silence_warnings { const_set(constant, val) }
    end

    begin
      block.call
    ensure
      constants.each do |constant, val|
        Kernel::silence_warnings { const_set(constant, saved_constants[constant]) }
      end
    end
  end

  def overwrite_constant(constant, value, object = Object)
    constant = constant.to_sym
    saved_constants[object] ||= {}
    saved_constants[object][constant] = object.const_get(constant) unless saved_constants[object].has_key?(constant)
    object.const_set(constant, value)
  end

  config.before :all do
    m = ActiveRecord::Migration
    m.verbose = false
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
  end

  config.after :all do
    m = ActiveRecord::Migration
    m.verbose = false
    m.drop_table :properties
    m.drop_table :properties_secondary_0
  end


end
