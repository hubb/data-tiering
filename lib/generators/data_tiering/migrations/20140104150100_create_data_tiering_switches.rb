class CreateDataTieringSwitches < ActiveRecord::Migration
  def self.up
    create_table :data_tiering_switches do |t|
      t.integer :current_active_number
      t.timestamps
    end
  end

  def self.down
    drop_table :data_tiering_switches
  end
end
