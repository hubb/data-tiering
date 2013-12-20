require 'spec_helper'
require 'data_tiering/switch'

describe DataTiering::Switch do

  subject { described_class.new }

  describe '#active_table_name_for' do

    it 'appends "secondary_0" by default' do
      subject.active_table_name_for("table_name").should == "table_name_secondary_0"
    end

    it 'appends "secondary_1" after the first switch' do
      subject.switch_current_active_number
      subject.active_table_name_for("table_name").should == "table_name_secondary_1"
    end

    it 'appends "secondary_0" after the second switch' do
      subject.switch_current_active_number
      subject.switch_current_active_number
      subject.active_table_name_for("table_name").should == "table_name_secondary_0"
    end

    it 'survives memcache evictions' do
      subject.switch_current_active_number
      DataTiering.configuration.cache.clear
      subject.active_table_name_for("table_name").should == "table_name_secondary_1"
    end

    it 'does not hit the database by default' do
      subject.switch_current_active_number
      described_class::DatabaseSwitch.delete_all
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
      subject.switch_current_active_number
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
        expect {
          subject.inactive_table_name_for("properties")
        }.to raise_error(DataTiering::Switch::NotSupported)
      end

    end

  end

  describe '#enabled?' do
    context "search" do
      it "is enabled when no constant is specified" do
        subject.should be_enabled
      end

      it "is disabled if the configuration search_enabled is false" do
        DataTiering.configuration.search_enabled = false
        described_class.new.should_not be_enabled
      end

      it "is enabled if the configuration search_enabled is true" do
        DataTiering.configuration.search_enabled = true
        described_class.new.should be_enabled
      end
    end

    context "sync" do
      subject { described_class.new(:sync) }

      it "is enabled when no constant is specified" do
        subject.should be_enabled
      end

      it "is disabled if the DATA_TIERING_SYNC_ENABLED is false" do
        DataTiering.configuration.sync_enabled = false
        subject.should_not be_enabled
      end

      it "is enabled if the DATA_TIERING_SYNC_ENABLED is true" do
        DataTiering.configuration.sync_enabled = true
        subject.should be_enabled
      end
    end
  end

end
