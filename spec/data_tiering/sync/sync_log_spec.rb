require 'spec_helper'
require 'data_tiering/sync/sync_log'

describe DataTiering::Sync::SyncLog do

  describe '.log' do

    subject { DataTiering::Sync::SyncLog }

    let(:t) { Time.zone.parse('2012-01-01 12:00') }

    it 'remembers the table name, start and end time of a run' do
      Timecop.freeze(t)
      subject.log('table name') do
        Timecop.freeze(t + 1.hour)
      end
      last = subject.last('table name')
      last.started_at.should == t
      last.finished_at.should == t + 1.hour
    end

    it 'only keeps the last one per table name' do
      subject.log('table 1') {}
      subject.log('table 1') {}
      subject.log('table 2') {}
      subject.all.collect(&:table_name).should =~ ['table 1', 'table 2']
    end

  end

end
