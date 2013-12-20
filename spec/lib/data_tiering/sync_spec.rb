require 'spec_helper'

describe DataTiering::Sync do

  subject { described_class }

  before do
    subject::SyncLog.delete_all
  end

  before :all do
    DataTiering.configuration.models_to_sync = [Property, Rate]
  end

  after :all do
    DataTiering.configuration.models_to_sync = []
  end

  class Rate < ::ActiveRecord::Base
    include DataTiering::Model
  end

  describe '.sync_and_switch!' do

    it 'uses a mutex' do
      Mutex.any_instance.should_receive(:synchronize)
      subject.sync_and_switch!
    end

    it 'swaps the current active table' do
      subject.switch.should_receive(:switch_current_active_number)
      subject.sync_and_switch!
    end

    it 'creates a SyncLog record for each model we want to sync' do
      DataTiering.configuration.models_to_sync = [Property, Rate]

      expect {
        subject.sync_and_switch!
      }.to change {
        described_class::SyncLog.count
      }.by(2)
    end

  end

  describe '.monitor' do

    let(:monitor) { double('monitor') }

    it 'instantiates and calls a Monitor' do
      described_class::Monitor.should_receive(:new).with(
        instance_of(DataTiering::Switch),
        %w(properties rates)
      ).and_return(monitor)

      monitor.should_receive(:monitor)
      subject.monitor
    end

  end

end
