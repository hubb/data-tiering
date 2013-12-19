# encoding: UTF-8

require 'data_tiering/switch'

module DataTiering
  module Sync

    # MODELS_TO_SYNC = [Property, Availability, Rate]
    MODELS_TO_SYNC = []

    module ClassMethods

      # Update all current inactive tables that are part of data tiering.
      # When that is done, switch the inactive and active tables
      #
      # Searches running at the time of the switch will keep querying the
      # former active table, so we need to wait a bit before doing the next
      # sync.
      def sync_and_switch!
        lock = Mutex.new
        lock.synchronize do
          sync_all_tables(switch)
          switch.switch_current_active_number
        end
      end

      def monitor
        DataTiering::Sync::Monitor.new(switch, MODELS_TO_SYNC.collect(&:table_name)).monitor
      end

      def switch
        @_switch ||= DataTiering::Switch.new(:sync)
      end

      private

      def sync_all_tables(switch)
        MODELS_TO_SYNC.each do |model|
          table_name = model.table_name
          inactive_table_name = switch.inactive_table_name_for(table_name)
          SyncTable.new(table_name, inactive_table_name).sync
        end
      end

    end

    extend ClassMethods

  end
end
