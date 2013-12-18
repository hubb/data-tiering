require 'spec_helper'
require 'data_tiering/sync/monitor'

describe DataTiering::Sync::Monitor do

  let(:now) { Time.parse("2020-01-01 12:00") }
  let(:switch) { DataTiering::Switch.new_with_stubs(:current_active_number => 1) }

  subject { described_class.new(switch, %w(table1 table2)) }

  describe 'monitor' do

    before do
      Timecop.freeze(now)
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'table1_secondary_1',
        :started_at => now - 10.seconds
      )
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'table2_secondary_1',
        :started_at => now - 20.seconds
      )
    end

    it 'reports the most stale sync log for an active table to datadog' do
      DATADOG.should_receive(:gauge).with('data_tiering.staleness', 20, anything)
      subject.monitor
    end

    it 'ignores the staleness of inactive tables' do
      DataTiering::Sync::SyncLog.create!(
        :table_name => 'table2_secondary_0',
        :started_at => now - 60.seconds
      )
      DATADOG.should_receive(:gauge).with('data_tiering.staleness', 20, anything)
      subject.monitor
    end

    it 'sends the current environment' do
      stub_rails_env 'the_environment'
      DATADOG.should_receive(:gauge).with(
        'data_tiering.staleness',
        anything,
        :tags => [ "environment:the_environment" ]
      )
      subject.monitor
    end

    it 'reports a big number on any exception' do
      subject.stub(:calculate_staleness).and_raise("some exception")
      DATADOG.should_receive(:gauge).with('data_tiering.staleness', 10_000, anything)
      proc { subject.monitor }.should raise_error("some exception")
    end

  end

end
