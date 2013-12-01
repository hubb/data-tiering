module DataTiering
  module Sync
    module SyncTable::SyncAll

      private

      def sync_all
        drop_all
        copy_all
      end

      def drop_all
        database_connection.execute(<<-SQL)
          TRUNCATE TABLE #{quote @inactive_table_name}
        SQL
      end

      def copy_all
        database_connection.execute(<<-SQL)
          INSERT INTO #{quote @inactive_table_name}
          SELECT * FROM #{quote @source_table_name}
        SQL
      end

    end
  end
end
