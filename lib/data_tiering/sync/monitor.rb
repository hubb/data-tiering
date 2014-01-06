require 'data_tiering/sync/sync_log'

module DataTiering
  module Sync

    class Monitor

      attr_reader :staleness

      def initialize(switch)
        @switch    = switch
        @staleness = nil
      end

      def monitor
        @staleness = calculate_staleness
      rescue
        @staleness = 10_000
      end

      private

      def calculate_staleness
        sync_logs_for_active_tables.collect(&:staleness).max
      end

      def sync_logs_for_active_tables
        DataTiering.configuration.models_to_sync.collect(&:table_name).collect do |table_name|
          SyncLog.last(@switch.active_table_name_for(table_name))
        end
      end

    end

  end
end
