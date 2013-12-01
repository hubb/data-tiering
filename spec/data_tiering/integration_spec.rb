require 'spec_helper'

describe DataTiering do

  subject { DataTiering::Sync }

  context 'on first run' do

    describe '.sync_and_switch!' do

      it 'interchanges the active and inactive table names' do
        switch = DataTiering::Switch.new
        old_active_table = switch.active_table_name_for("properties")
        old_inactive_table = switch.inactive_table_name_for("properties")
        subject.sync_and_switch!
        switch = DataTiering::Switch.new
        new_active_table = switch.active_table_name_for("properties")
        new_inactive_table = switch.inactive_table_name_for("properties")
        old_active_table.should_not == old_inactive_table
        new_active_table.should == old_inactive_table
        new_inactive_table.should == old_active_table
      end

      it 'results in current property data in the new active table' do
        Property.store_with_values(:name => "property 1")
        Property.store_with_values(:name => "property 2")
        subject.sync_and_switch!
        active_table_name = DataTiering::Switch.new.active_table_name_for("properties")
        active_properties = Class.new(::ActiveRecord::Base) do
          set_table_name(active_table_name)
        end
        active_properties.all.collect(&:name).should =~ ["property 1", "property 2"]
      end

    end

  end

  context 'on subsequent runs' do

    describe '.sync_and_switch!' do

      it 'interchanges the active and inactive table names' do
        switch = DataTiering::Switch.new
        old_active_table = switch.active_table_name_for("properties")
        old_inactive_table = switch.inactive_table_name_for("properties")
        subject.sync_and_switch!
        switch = DataTiering::Switch.new
        new_active_table = switch.active_table_name_for("properties")
        new_inactive_table = switch.inactive_table_name_for("properties")
        old_active_table.should_not == old_inactive_table
        new_active_table.should == old_inactive_table
        new_inactive_table.should == old_active_table
      end

      it 'results in current property data in the new active table' do
        Property.store_with_values(:name => "property 1")
        subject.sync_and_switch!
        Property.store_with_values(:name => "property 2")
        subject.sync_and_switch!
        active_table_name = DataTiering::Switch.new.active_table_name_for("properties")
        active_properties = Class.new(::ActiveRecord::Base) do
          set_table_name(active_table_name)
        end
        active_properties.all.collect(&:name).should =~ ["property 1", "property 2"]
      end

    end

  end

  context 'mysql timestamps' do

    def row_touched_at(model)
      # the timestamp is stored in db local time
      # so we'll have to convert it ourselves
      Property.connection.select_value(<<-SQL)
        SELECT ADDTIME(row_touched_at, TIMEDIFF('#{Time.current.to_s(:db)}', NOW()))
        FROM properties WHERE id = #{model.id}
      SQL
    end

    let(:property) { Property.store_with_values }
    let(:old_property) { Property.store_with_values(:row_touched_at => 1.year.ago); Property.last }

    it 'should be set when a new record is created' do
      time = row_touched_at(property)
      time.should > 5.seconds.ago
      time.should <= Time.current
    end

    it 'should be set when an existing record is saved' do
      time = row_touched_at(old_property)
      old_property.save(false)
      row_touched_at(old_property).should > time
    end

    it 'should be updated on bulk updates' do
      time = row_touched_at(old_property)
      Property.update_all(:name => "new name") # random column
      row_touched_at(old_property).should > time
    end

  end

end
