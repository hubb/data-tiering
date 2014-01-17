require 'spec_helper'

class DataTieringSwitches < ActiveRecord::Base; end;
class DataTieringSyncLogs < ActiveRecord::Base; end;

describe DataTiering::SetupMigration do
  subject { Class.new(ActiveRecord::Migration).extend(described_class) }

  it "is an active record migration" do
    subject.ancestors.should include(ActiveRecord::Migration)
  end

  describe "#up" do
    before do
      silence_stream(STDOUT) { subject.down }
      silence_stream(STDOUT) { subject.up }
    end

    it "creates a data tiering switches table with the correct attributes" do
      data_tiering_switch = DataTieringSwitches.new
      data_tiering_switch.attributes.should include("current_active_number")
    end

    it "creates a data tiering sync logs table with the correct attributes" do
      data_tiering_sync_logs = DataTieringSyncLogs.new
      data_tiering_sync_logs.attributes.should include("table_name")
      data_tiering_sync_logs.attributes.should include("started_at")
      data_tiering_sync_logs.attributes.should include("finished_at")
    end

    it "results in functional models" do
      DataTieringSwitches.create(:current_active_number => 1)
      DataTieringSwitches.count.should == 1

      DataTieringSyncLogs.create(:table_name => 'hello-world', :started_at => 1.day.ago, :finished_at => 1.hour.ago)
      DataTieringSyncLogs.count.should == 1
    end
  end

  describe "#down" do
    before do
      silence_stream(STDOUT) { subject.up } rescue Mysql2::Error # can't be sure of state of tables
      silence_stream(STDOUT) { subject.down }
    end

    it "drops the data tiering switches table" do
      expect {
        DataTieringSwitches.create
      }.to raise_error
    end

    it "drops the data tiering sync logs table" do
      expect {
        DataTieringSyncLogs.create
      }.to raise_error
    end
  end
end
