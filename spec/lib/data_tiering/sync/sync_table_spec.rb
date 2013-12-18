require 'spec_helper'
require 'data_tiering/sync/sync_table'

shared_examples_for 'a basic table sync mechanism' do

  it 'copies over all properties' do
    DataTieringSyncSpec::Property.create!(:name => "property 1")
    DataTieringSyncSpec::Property.create!(:name => "property 2")
    sync
    DataTieringSyncSpec::Property.all.collect(&:name).should =~ ["property 1", "property 2"]
  end

  it 'does not change ids' do
    DataTieringSyncSpec::Property.create!
    DataTieringSyncSpec::Property.create!
    sync
    DataTieringSyncSpec::Property.all.collect(&:id).should =~ Property.all.collect(&:id)
  end

end


describe DataTiering::Sync::SyncTable do
  before do
    Rails = double(:env => double(:test? => true))
  end


  def build_sync_table
    DataTiering::Sync::SyncTable.new("properties", "properties_secondary_0")
  end

  describe '#delta_sync_possible?' do

    it 'is true if there is a secondary table with the same schema' do
      build_sync_table.send(:recreate_inactive_table)
      DataTieringSyncSpec::Property.reset_column_information
      build_sync_table.send(:delta_sync_possible?).should be_true
    end

    it 'is false if the secondary table is missing' do
      build_sync_table.send(:drop_inactive_table)
      build_sync_table.send(:delta_sync_possible?).should be_false
    end

    it 'is false if the secondary tables schema is different' do
      build_sync_table.send(:recreate_inactive_table)
      DataTieringSyncSpec::Property.reset_column_information
      ActiveRecord::Base.connection.remove_column "properties_secondary_0", "name"
      build_sync_table.send(:delta_sync_possible?).should be_false
    end

  end

  describe '#sync' do

    context 'when using complete syncing' do

      before do
        build_sync_table.send(:drop_inactive_table)
      end

      def sync
        sync_table = build_sync_table
        sync_table.stub :delta_sync_possible? => false
        sync_table.sync
      end

      it 'calls sync_all' do
        sync_table = build_sync_table
        sync_table.should_receive(:sync_all)
        sync_table.sync
      end

      it_should_behave_like 'a basic table sync mechanism'

      it 'creates secondary table with the correct columns' do
        DataTieringSyncSpec::Property.columns.collect(&:name).should == Property.columns.collect(&:name)
      end

    end

    context 'when using delta syncing' do

      before(:all) do
        build_sync_table.send(:recreate_inactive_table)
      end

      def sync
        sync_table = build_sync_table
        sync_table.stub :delta_sync_possible? => true
        sync_table.sync
      end

      it 'calls sync_deltas' do
        sync = DataTiering::Sync::SyncTable.new("properties", "properties_secondary_0")
        sync.should_receive(:sync_deltas)
        sync.sync
      end

      it 'sets the db isolation level to "READ COMMITTED"' do
        sync = DataTiering::Sync::SyncTable.new("properties", "properties_secondary_0")
        sync.should_receive(:with_transaction_isolation_level).with("READ COMMITTED")
        sync.sync
      end

      it_should_behave_like 'a basic table sync mechanism'

      def set_row_touched_at(record)
        # we have to override timestamps, which are stored in local db time
        record.class.update_all("row_touched_at = '#{Time.current.localtime.to_s(:db)}'", :id => record.id)
      end

      it 'syncs changes close to the last seen change' do
        property = Property.create!(:name => "old name")
        sync
        Timecop.freeze(5.minutes.ago) do
          property.name = "new name"
          property.save(false)
          set_row_touched_at(property)
        end
        sync
        DataTieringSyncSpec::Property.first.name.should == "new name"
      end

      it 'does not sync changes that happened a while before the last seen change' do
        property = Property.create!(:name => "old name")
        sync
        Timecop.freeze(60.minutes.ago) do
          property.name = "new name"
          property.save(false)
          set_row_touched_at(property)
        end
        sync
        DataTieringSyncSpec::Property.first.name.should == "old name"
      end

      it 'syncs new properties' do
        DataTieringSyncSpec::Property.create!(:name => "property 1")
        sync
        DataTieringSyncSpec::Property.create!(:name => "property 2")
        sync
        DataTieringSyncSpec::Property.count.should == 2
      end

      it 'syncs changed properties' do
        property = Property.create!(:name => "old name")
        sync
        property.name = "new name"
        property.save(false)
        sync
        DataTieringSyncSpec::Property.first.name.should == "new name"
      end

      it 'syncs deletions, but does not touch the regular table' do
        DataTieringSyncSpec::Property.create!(:name => "property 1")
        property = DataTieringSyncSpec::Property.create!(:name => "property 2")
        sync
        property.delete
        sync
        DataTieringSyncSpec::Property.count.should == 1
        DataTieringSyncSpec::Property.count.should == 1
      end

      context "batch processing" do

        before do
          @original_contstant_value = DataTiering::Sync::SyncTable::SyncDeltas::BATCH_SIZE
          DataTiering::Sync::SyncTable::SyncDeltas::BATCH_SIZE = 1000
          DataTieringSyncSpec::Property.create!(:id => 100)
          DataTieringSyncSpec::Property.create!(:id => 1100)
        end

        after do
          DataTiering::Sync::SyncTable::SyncDeltas::BATCH_SIZE = @original_contstant_value
        end

        it 'copies all properties when there is more than one batch' do
          sync
          DataTieringSyncSpec::Property.all.collect(&:id).should =~ [100, 1100]
        end

        it 'deletes properties when there is more than one batch' do
          sync
          DataTieringSyncSpec::Property.find(1100).delete
          sync
          DataTieringSyncSpec::Property.all.collect(&:id).should =~ [100]
        end

        it 'only takes timestamps from an already processed batch' do
          Timecop.freeze(1.month.from_now) do
            DataTieringSyncSpec::Property.find(100).save(false)
          end
          sync
          DataTieringSyncSpec::Property.all.collect(&:id).should =~ [100, 1100]
        end

        it 'performs only one insert per batch' do
          DataTiering::Sync::SyncLog.stub(:log).and_yield
          ActiveRecord::Base.connection.should_receive(:insert).exactly(:twice)
          sync
        end

        it 'performes only one delete per batch' do
          sync
          DataTieringSyncSpec::Property.delete_all
          DataTiering::Sync::SyncLog.stub(:log).and_yield
          ActiveRecord::Base.connection.should_receive(:delete).exactly(:twice)
          sync
        end

      end

    end

  end

  describe '#with_transaction_isolation_level' do

    subject { build_sync_table }

    def current_transaction_isolation_level
      ActiveRecord::Base.connection.select_value(<<-SQL).sub('-', ' ')
        SELECT @@tx_isolation;
      SQL
    end

    it 'set the transaction isolation level inside the block' do
      subject.send(:with_transaction_isolation_level, "READ COMMITTED") do
        current_transaction_isolation_level
      end.should == "READ COMMITTED"
    end

    it 'resets it afterwards' do
      subject.send(:with_transaction_isolation_level, "READ COMMITTED") do
      end
      current_transaction_isolation_level.should == "REPEATABLE READ"
    end

  end

end
