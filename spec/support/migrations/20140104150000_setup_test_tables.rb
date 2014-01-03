class SetupTestTables < ActiveRecord::Migration
  def self.up
    create_table :properties do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    create_table :rates do |t|
      t.string :name
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end

    [:properties, :rates].each do |t|
      execute <<-SQL
        ALTER TABLE #{t}
        ADD row_touched_at TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
      SQL

      update <<-SQL
        UPDATE #{t}
        SET row_touched_at = '2000-01-01 00:00:01'
      SQL
    end
  end

  def self.down
    drop_table :properties
    drop_table :rates
  end
end
