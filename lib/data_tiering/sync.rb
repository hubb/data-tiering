# encoding: UTF-8

require 'data_tiering/switch'
require 'data_tiering/sync/monitor'

module DataTiering
  module Sync

    module ClassMethods

      # Update all current inactive tables that are part of data tiering.
      # When that is done, switch the inactive and active tables
      #
      # Queries running at the time of the switch will keep querying the
      # former active table, so we need to wait a bit before doing the next
      # sync.
      def sync_and_switch!
        lock = Mutex.new
        lock.synchronize do
          switch.sync_all_tables
          switch.switch_current_active_number
        end
      end

      def monitor
        DataTiering::Sync::Monitor.new(switch).monitor
      end

      def switch
        @_switch ||= Switch.new(:sync)
      end

    end

    extend ClassMethods

  end
end
