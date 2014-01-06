require 'spec_helper'
require 'data_tiering/sync/monitor'
require 'data_tiering/sync/sync_log'

describe DataTiering::Sync::Monitor do

  let(:time)   { Time.parse("12pm, 1st January 2020") }
  let(:switch) {
    s = DataTiering::Switch.new
    s.stub(:current_active_number => 1)
    s
  }

  subject { described_class.new(switch) }

  describe 'monitor' do

    before do
      Time.stub :current => time
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'properties_secondary_1',
        :started_at => time - 20.seconds,
        :finished_at => time - 5.seconds
      )
    end

    it 'reports the most stale sync log for an active table' do
      subject.monitor
      subject.staleness.should == 20
    end

    it 'ignores the staleness of inactive tables' do
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'properties_secondary_0',
        :started_at => time - 60.seconds,
        :finished_at => time - 55.seconds
      )

      subject.monitor
      subject.staleness.should == 20
    end

    it 'reports a big number on any exception' do
      subject.stub(:calculate_staleness).and_raise("some exception")

      subject.monitor
      subject.staleness.should == 10_000
    end

  end

end
