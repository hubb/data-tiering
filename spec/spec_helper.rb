# encoding: UTF-8

require 'pry'
require 'pry-nav'

require 'active_record'
require 'timecop'

require 'rspec'
require 'data_tiering'
require 'data_tiering/sync'

require 'support/connection'

RSpec.configure do |config|

  $saved_constants = {}

  # Allow constant stubbing
  def with_constants(constants, &block)
    constants.each do |constant, val|
      $saved_constants[constant] = const_get(constant) if const_defined?(constant)
      Kernel::silence_warnings { const_set(constant, val) }
    end

    begin
      block.call
    ensure
      constants.each do |constant, val|
        Kernel::silence_warnings { const_set(constant, $saved_constants[constant]) }
      end
    end
  end

  def overwrite_constant(constant, value, object = Object)
    constant = constant.to_sym
    $saved_constants[object] ||= {}
    $saved_constants[object][constant] = object.const_get(constant) unless $saved_constants[object].has_key?(constant)
    Kernel::silence_warnings { object.const_set(constant, value) }
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
