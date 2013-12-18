require 'spec_helper'

describe DataTiering::Switch do

  def switch_current_active_number
    DataTiering::Switch.new.switch_current_active_number
  end


  subject { DataTiering::Switch.new(cache) }

  describe '#active_table_name_for' do

    it 'appends "secondary_0" by default' do
      subject.active_table_name_for("table_name").should == "table_name_secondary_0"
    end

    it 'appends "secondary_1" after the first switch' do
      switch_current_active_number
      subject.active_table_name_for("table_name").should == "table_name_secondary_1"
    end

    it 'appends "secondary_0" after the second switch' do
      switch_current_active_number
      switch_current_active_number
      subject.active_table_name_for("table_name").should == "table_name_secondary_0"
    end

    it 'survives memcache evictions' do
      switch_current_active_number
      Rails.cache.clear
      subject.active_table_name_for("table_name").should == "table_name_secondary_1"
    end

    it 'does not hit the database by default' do
      switch_current_active_number
      DataTiering::Switch::DatabaseSwitch.delete_all
      subject.active_table_name_for("table_name").should == "table_name_secondary_1"
    end

  end

  describe '#inactive_table_name_for' do

    it 'appends "secondary_1" by default' do
      subject.inactive_table_name_for("table_name").should == "table_name_secondary_1"
    end

    it 'appends "secondary_0" after the first switch' do
      subject.switch_current_active_number
      subject.inactive_table_name_for("table_name").should == "table_name_secondary_0"
    end

  end

  describe '#active_scope_for' do

    it 'returns a scope on the model' do
      subject.active_scope_for(Property).base_class.should == Property
    end

    it 'returns a scope using the secondary_0 table' do
      subject.active_scope_for(Property).scope(:find)[:from].should == "`properties_secondary_0` AS `properties`"
    end

    it 'returns a scope using the secondary_1 table after the first switch' do
      switch_current_active_number
      subject.active_scope_for(Property).scope(:find)[:from].should == "`properties_secondary_1` AS `properties`"
    end

  end

  describe '#inactive_scope_for' do

    it 'returns a scope on the model' do
      subject.inactive_scope_for(Property).base_class.should == Property
    end

    it 'returns a scope using the secondary_0 table' do
      subject.inactive_scope_for(Property).scope(:find)[:from].should == "`properties_secondary_1` AS `properties`"
    end

  end

  describe '#aliased_active_table_sql' do

    it 'returns a sql fragment aliasing the current active table to the regular table name' do
      subject.aliased_active_table_sql("properties").should == "`properties_secondary_0` AS `properties`"
    end

  end

  describe '#aliased_inactive_table_sql' do

    it 'returns a sql fragment aliasing the current inactive table to the regular table name' do
      subject.aliased_inactive_table_sql("properties").should == "`properties_secondary_1` AS `properties`"
    end

  end

  context 'when disabled' do

    before do
      subject.disable
    end

    describe '#aliased_active_table_sql' do

      it 'should return a fragment using the standard table name' do
        subject.aliased_active_table_sql("properties").should == "`properties` AS `properties`"
      end

    end

    describe '#active_scope_for' do

      it 'should return a scope using the regular table' do
        subject.active_scope_for(Property).scope(:find)[:from].should == "`properties` AS `properties`"
      end

    end

    describe '#active_table_name_for' do

      it 'should return the standard table name' do
        subject.active_table_name_for("properties").should == "properties"
      end

    end

    describe '#inactive_table_name_for' do

      it 'should raise an error' do
        proc do
          subject.inactive_table_name_for("properties")
        end.should raise_error(DataTiering::Switch::NotSupported)
      end

    end

  end

  describe '#enabled?' do

    it 'is enabled for search iff DATA_TIERING_SEARCH_ENABLED is true' do
      described_class.new(cache).should be_enabled
      with_constants(:DATA_TIERING_SEARCH_ENABLED => false) do
        described_class.new.should_not be_enabled
      end
    end

    it 'is enabled for sync iff DATA_TIERING_SYNC_ENABLED is true' do
      described_class.new(cache, :sync).should be_enabled
      with_constants(:DATA_TIERING_SYNC_ENABLED => false) do
        described_class.new(cache, :sync).should_not be_enabled
      end
    end

  end

end
