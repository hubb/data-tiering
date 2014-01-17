module DataTiering
  module SetupMigration
    def self.extended(by)
      by.singleton_class.class_eval do
        def up
          create_table :data_tiering_switches do |t|
            t.integer :current_active_number
            t.timestamps
          end

          create_table :data_tiering_sync_logs do |t|
            t.string :table_name
            t.datetime :started_at
            t.datetime :finished_at
          end
        end

        def down
          drop_table :data_tiering_switches
          drop_table :data_tiering_sync_logs
        end
      end
    end
  end
end
