module DataTiering
  module Sync
    module SyncTable::SyncDeltas


      private

      def sync_deltas
        @updated_at_threshold = calculate_updated_at_threshold
        with_transaction_isolation_level("READ COMMITTED") do
          in_batches do |from_id, to_id|
            sync_deletions(from_id, to_id)
            sync_updates(from_id, to_id)
          end
        end
      end

      def with_transaction_isolation_level(level)
        old_transaction_isolation_level = database_connection.select_value(<<-SQL).sub('-', ' ')
          SELECT @@tx_isolation;
        SQL
        set_transaction_isolation_level(level)
        yield
      ensure
        begin
          set_transaction_isolation_level(old_transaction_isolation_level)
        rescue
          # we really, really don't want this to persist
          database_connection.reconnect!
          raise
        end
      end

      def set_transaction_isolation_level(level)
        database_connection.execute(<<-SQL)
          SET SESSION TRANSACTION ISOLATION LEVEL #{level}
        SQL
      end

      def calculate_updated_at_threshold
        last_sync_log = SyncLog.last(@inactive_table_name)
        if last_sync_log
          # paranoia, there might have been transactions in flight etc
          last_sync_log.started_at - 10.minutes
        else
          beginning_of_time
        end
      end

      def beginning_of_time
        Time.at(0)
      end

      def in_batches
        1.step(max_id, DataTiering.configuration.batch_size) do |from_id|
          yield from_id, from_id + DataTiering.configuration.batch_size - 1
        end
      end

      def max_id
        @max_id ||= [calculate("MAX(id)", @source_table_name), calculate("MAX(id)", @inactive_table_name)].compact.max || 0
      end

      def calculate(function, table_name)
        database_connection.select_value(<<-SQL)
          SELECT #{function}
          FROM #{quote table_name}
        SQL
      end

      def sync_deletions(from_id, to_id)
        deleted_ids = database_connection.select_values(<<-SQL)
          SELECT inactive_table.id
          FROM #{quote @inactive_table_name} AS inactive_table
          LEFT JOIN
            #{quote @source_table_name} AS source_table
            ON source_table.id = inactive_table.id
          WHERE
            inactive_table.id BETWEEN #{from_id} AND #{to_id} AND
            source_table.id IS NULL
        SQL
        if deleted_ids.any?
          database_connection.delete(<<-SQL)
            DELETE
            FROM #{quote @inactive_table_name}
            WHERE id IN (#{deleted_ids.join(',')})
          SQL
        end
      end

      def sync_updates(from_id, to_id)
        database_connection.insert <<-SQL
          REPLACE INTO #{quote @inactive_table_name}
          SELECT * FROM #{quote @source_table_name}
          WHERE
            id BETWEEN #{from_id} AND #{to_id} AND
            row_touched_at >= #{convert_to_local_time_sql(@updated_at_threshold)}
        SQL
      end

      def convert_to_local_time_sql(time)
        "ADDTIME('#{time.to_s(:db)}', TIMEDIFF(NOW(), '#{Time.current.to_s(:db)}'))"
      end

    end
  end
end
