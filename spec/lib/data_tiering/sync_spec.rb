require 'spec_helper'

describe DataTiering::Sync do

  subject { DataTiering::Sync }

  describe '.sync_and_switch!' do

    let(:switch) { double("switch").as_null_object }
    let(:sync_table) { double("sync_table").as_null_object }

    before do
      DataTiering::Switch.stub(:new).with(:sync).and_return(switch)
      DataTiering::Sync::SyncTable.stub :new => sync_table
    end

    it 'syncs the properties, availabilities and rates tables' do
      switch.stub(:inactive_table_name_for).with("properties").and_return("properties_inactive_table")
      switch.stub(:inactive_table_name_for).with("availabilities").and_return("availabilities_inactive_table")
      switch.stub(:inactive_table_name_for).with("rates").and_return("rates_inactive_table")

      sync_property_table = double("sync_property_table")
      sync_availability_table = double("sync_availability_table")
      sync_rate_table = double("sync_rate_table")

      DataTiering::Sync::SyncTable.stub(:new).with("properties", "properties_inactive_table").and_return(sync_property_table)
      DataTiering::Sync::SyncTable.stub(:new).with("availabilities", "availabilities_inactive_table").and_return(sync_availability_table)
      DataTiering::Sync::SyncTable.stub(:new).with("rates", "rates_inactive_table").and_return(sync_rate_table)

      sync_property_table.should_receive(:sync).and_call_original
      sync_availability_table.should_receive(:sync)
      sync_rate_table.should_receive(:sync)
      subject.sync_and_switch!
    end

    it 'uses a mutex' do
      Mutex.any_instance.should_receive(:synchronize)
      subject.sync_and_switch!
    end

    it 'swaps the current active table' do
      switch.should_receive(:switch_current_active_number)
      subject.sync_and_switch!
    end

  end

  describe '.monitor' do

    it 'instantiates and calls a Monitor' do
      monitor = double('monitor')
      DataTiering::Sync::Monitor.should_receive(:new).with(
        instance_of(DataTiering::Switch),
        %w(properties availabilities rates)
      ).and_return(monitor)
      monitor.should_receive(:monitor)
      subject.monitor
    end

  end

end
