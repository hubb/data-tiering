# encoding: UTF-8

# DataTiering::Switch manages pointers to tables that are part of data tiering
#
# For every model that takes part in the data tiering there are 3 tables:
# - the "regular" table, which will keep receiving all writes and reads from
#   code that does not explicitly make use of data tiering
# - the "active" table, which will only receive reads (e.g. from the search), but no updates
#   it will typically lag behind the "regular" table by a few minutes
# - the "inactive" table which receives neither reads nor writes from the app
#
# DataTiering::Sync.sync_and_switch! will sync over all changes from the "regular"
# to the "inactive" table. Then the "active" and "inactive" tables are switched.
#
# The switch is atomic. Currently running searches will keep using the formerly "active", now
# "inactive" table, though. This is fine since they run only a couple of seconds, and we
# will only sync every few minutes.

require 'active_record'

module DataTiering

  class Switch

    class NotSupported < StandardError; end

    class DatabaseSwitch < ::ActiveRecord::Base
      set_table_name 'data_tiering_switches'
    end

    def initialize(cache, context = :search)
      case context
      when :search
        @enabled = DataTiering.configuration.search_enabled
      when :sync
        @enabled = DataTiering.configuration.sync_enabled
      else
        raise ArgumentError.new("valid contexts are :search and :sync")
      end
    end

    def enabled?
      @enabled
    end

    def disable
      @enabled = false
    end

    def aliased_active_table_sql(table_name)
      aliased_table_sql(table_name, current_active_number)
    end

    def aliased_inactive_table_sql(table_name)
      assert_enabled
      aliased_table_sql(table_name, current_inactive_number)
    end

    def active_table_name_for(table_name)
      table_name_for(table_name, current_active_number)
    end

    def inactive_table_name_for(table_name)
      assert_enabled
      table_name_for(table_name, current_inactive_number)
    end

    def active_scope_for(model)
      scope_for(model, current_active_number)
    end

    def inactive_scope_for(model)
      assert_enabled
      scope_for(model, current_inactive_number)
    end

    # TODO: if we move to a cache with better guarantees (i.e. Redis), this can be simplified
    def switch_current_active_number
      @current_active_number = 1 - current_active_number
      store_current_active_number_in_database
      store_current_active_number_in_cache
    end


    private

    def assert_enabled
      @enabled or raise NotSupported.new("not supported when data tiering is disabled")
    end

    def current_active_number
      @current_active_number ||= current_active_number_from_cache || current_active_number_from_database || 0
    end

    def current_inactive_number
      1 - current_active_number
    end

    def cache_key
      "DataTiering#CurrentActiveNumber"
    end

    def current_active_number_from_cache
      cache.read(cache_key).try(:to_i)
    end

    def current_active_number_from_database
      # safeguard against memcache evictions
      DatabaseSwitch.first.try(:current_active_number)
    end

    def store_current_active_number_in_cache
      cache.write(cache_key, @current_active_number)
    end

    def store_current_active_number_in_database
      # safeguard against memcache evictions
      DatabaseSwitch.transaction do
        database_switch = DatabaseSwitch.first || DatabaseSwitch.new
        database_switch.current_active_number = @current_active_number
        database_switch.save!
      end
    end

    def table_name_for(table_name, number)
      if @enabled
        "#{table_name}_secondary_#{number}"
      else
        table_name
      end
    end

    def scope_for(model, number)
      model.scoped(:from => aliased_table_sql(model.table_name, number))
    end

    def aliased_table_sql(table_name, number)
      "#{quote(table_name_for(table_name, number))} AS #{quote(table_name)}"
    end

    def quote(table_name)
      ::ActiveRecord::Base.connection.quote_table_name(table_name)
    end

  end

end
