require 'spec_helper'
require 'data_tiering/sync/monitor'
require 'data_tiering/sync/sync_log'

describe DataTiering::Sync::Monitor do

  let(:now) { Time.parse("2020-01-01 12:00") }
  let(:switch) {
    s = DataTiering::Switch.new(cache)
    s.stub(:current_active_number => 1)
    s
  }

  subject { described_class.new(switch, %w(table1 table2)) }

  describe 'monitor' do

    before do
      Timecop.freeze(now)
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'table1_secondary_1',
        :started_at => now - 10.seconds,
        :finished_at => now - 5.seconds
      )
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'table2_secondary_1',
        :started_at => now - 20.seconds,
        :finished_at => now - 5.seconds
      )
    end

    it 'reports the most stale sync log for an active table to datadog' do
      subject.monitor
      subject.staleness.should == 20
    end

    it 'ignores the staleness of inactive tables' do
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'table2_secondary_0',
        :started_at => now - 60.seconds,
        :finished_at => now - 55.seconds
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
