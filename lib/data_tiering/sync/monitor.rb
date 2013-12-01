module DataTiering
  module Sync

    class Monitor

      def initialize(switch, table_names)
        @switch = switch
        @table_names = table_names
      end

      def monitor
        staleness = calculate_staleness
      rescue
        staleness = 10_000
        raise
      ensure
        DATADOG.gauge('data_tiering.staleness', staleness, :tags => datadog_tags)
      end

      private

      def calculate_staleness
        sync_logs_for_active_tables.collect(&:staleness).max
      end

      def sync_logs_for_active_tables
        @table_names.collect do |table_name|
          SyncLog.last(@switch.active_table_name_for(table_name))
        end
      end

      def datadog_tags
        [
          "environment:#{Rails.env}"
        ]
      end

    end

  end
end
