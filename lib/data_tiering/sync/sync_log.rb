module DataTiering
  module Sync

    class SyncLog < ::ActiveRecord::Base
      set_table_name :data_tiering_sync_logs

      validates_presence_of :table_name, :started_at, :finished_at

      named_scope :for_table, proc { |table_name | { :conditions => { :table_name => table_name } } }


      def self.last(table_name)
        SyncLog.for_table(table_name).first
      end

      def self.log(table_name, &block)
        new(:table_name => table_name).log(&block)
      end

      def log
        self.started_at = Time.current
        yield
        self.finished_at = Time.current
        save_and_remove_previous
      end

      def staleness
        Time.current - started_at
      end


      private

      def save_and_remove_previous
        self.class.transaction do
          SyncLog.for_table(self.table_name).delete_all
          save!
        end
      end

    end

  end
end
