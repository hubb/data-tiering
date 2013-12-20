# encoding: UTF-8

require 'data_tiering/sync/sync_log'

module DataTiering
  module Sync
    class SyncTable

      require 'data_tiering/sync/sync_table/sync_all'
      require 'data_tiering/sync/sync_table/sync_deltas'

      include SyncAll
      include SyncDeltas


      def initialize(source_table_name, inactive_table_name)
        @source_table_name = source_table_name
        @inactive_table_name = inactive_table_name
      end

      def sync
        SyncLog.log(@inactive_table_name) do
          sync_data
        end
      end


      private

      def sync_data
        if delta_sync_possible?
          sync_deltas
        else
          notify_about_schema_change
          recreate_inactive_table
          sync_all
        end
      end

      def database_connection
        ::ActiveRecord::Base.connection
      end

      def quote(table_name)
        database_connection.quote_table_name(table_name)
      end

      def calculate(function, table_name)
        database_connection.select_value(<<-SQL)
          SELECT #{function}
          FROM #{quote table_name}
        SQL
      end

      def delta_sync_possible?
        inactive_table_present? && inactive_table_schema_matching?
      end

      def inactive_table_present?
        database_connection.table_exists?(@inactive_table_name)
      end

      def inactive_table_schema_matching?
        significant_schema_for(@inactive_table_name) == significant_schema_for(@source_table_name)
      end

      def significant_schema_for(table_name)
        schema = database_connection.select_rows(<<-SQL).first.last
          SHOW CREATE TABLE #{quote table_name}
        SQL
        schema.sub(/CREATE TABLE `.*`/, '').sub(/AUTO_INCREMENT=\d* /, '')
      end

      def notify_about_schema_change
        unless DataTiering.configuration.env == 'test'
          # this should only ever happen within a rake task
          puts "Data tiering: Schema for #{@inactive_table_name} out of date"
          puts "I'll update it. This will take some time."
        end
      end

      def recreate_inactive_table
        drop_inactive_table
        create_inactive_table
      end

      def drop_inactive_table
        database_connection.execute(<<-SQL)
          DROP TABLE IF EXISTS #{quote @inactive_table_name}
        SQL
      end

      def create_inactive_table
        database_connection.execute(<<-SQL)
          CREATE TABLE #{quote @inactive_table_name} LIKE #{quote @source_table_name}
        SQL
      end

    end
  end
end
