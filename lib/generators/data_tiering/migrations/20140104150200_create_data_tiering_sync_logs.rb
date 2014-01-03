class CreateDataTieringSyncLogs < ActiveRecord::Migration
  def self.up
    create_table :data_tiering_sync_logs do |t|
      t.string :table_name
      t.datetime :started_at
      t.datetime :finished_at
    end
  end

  def self.down
    drop_table :data_tiering_sync_logs
  end
end
