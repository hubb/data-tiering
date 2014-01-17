module DataTiering
  module ModelMigration
    def self.extended(by)
      by.singleton_class.class_eval do
        def table_name=(model_table_name)
          @table_name = model_table_name
        end

        def up
          raise 'table_name cannot be blank.' if @table_name.nil?

          execute <<-SQL
            ALTER TABLE #{@table_name}
            ADD row_touched_at TIMESTAMP
            DEFAULT CURRENT_TIMESTAMP
            ON UPDATE CURRENT_TIMESTAMP
          SQL

          update <<-SQL
            UPDATE #{@table_name}
            SET row_touched_at = '2000-01-01 00:00:01'
          SQL
        end
      end
    end
  end
end
