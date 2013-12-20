require 'spec_helper'
require 'data_tiering/sync/sync_table'

shared_examples_for 'a basic table sync mechanism' do

  before do
    Property.create!(:name => "property 1")
    Property.create!(:name => "property 2")
  end

  it 'copies over all properties' do
    subject.sync

    DataTieringSyncSpec::Property.all.collect(&:name).should =~ ["property 1", "property 2"]
  end

  it 'does not change ids' do
    subject.sync

    DataTieringSyncSpec::Property.all.collect(&:id).should =~ Property.all.collect(&:id)
  end

end


describe DataTiering::Sync::SyncTable do
  subject { described_class.new("properties", "properties_secondary_0") }

  describe '#delta_sync_possible?' do
    it 'is true if there is a secondary table with the same schema' do
      subject.send(:recreate_inactive_table)
      DataTieringSyncSpec::Property.reset_column_information
      subject.send(:delta_sync_possible?).should be_true
    end

    it 'is false if the secondary table is missing' do
      subject.send(:drop_inactive_table)
      subject.send(:delta_sync_possible?).should be_false
    end

    it 'is false if the secondary tables schema is different' do
      subject.send(:recreate_inactive_table)
      DataTieringSyncSpec::Property.reset_column_information
      ActiveRecord::Base.connection.remove_column "properties_secondary_0", "name"
      subject.send(:delta_sync_possible?).should be_false
    end
  end

  describe '#sync' do

    context 'when delta syncing is not possible' do
      before do
        subject.stub :delta_sync_possible? => false
      end

      it 'calls sync_all' do
        subject.should_receive(:sync_all)
        subject.sync
      end

      it_should_behave_like 'a basic table sync mechanism'

      it 'creates secondary table with the correct columns' do
        subject.send(:recreate_inactive_table)
        subject.sync
        DataTieringSyncSpec::Property.columns.collect(&:name).should == Property.columns.collect(&:name)
      end

    end

    context 'when delta syncing is possible' do
      before do
        subject.send(:recreate_inactive_table)
        subject.stub(:delta_sync_possible? => true)
      end

      it 'calls sync_deltas' do
        subject.should_receive(:sync_deltas)
        subject.sync
      end

      it 'sets the db isolation level to "READ COMMITTED"' do
        subject.should_receive(:with_transaction_isolation_level).with("READ COMMITTED")
        subject.sync
      end

      it_should_behave_like 'a basic table sync mechanism'

      def set_row_touched_at(record)
        # we have to override timestamps, which are stored in local db time
        record.class.update_all("row_touched_at = '#{Time.current.localtime.to_s(:db)}'", :id => record.id)
      end

      it 'syncs changes close to the last seen change' do
        property = Property.create!(:name => "old name")
        subject.sync
        DataTieringSyncSpec::Property.first.name.should == "old name"

        Timecop.freeze(Time.current - 5.minutes) do
          property.name = "new name"
          property.save(false)
          set_row_touched_at(property)
        end
        subject.sync
        DataTieringSyncSpec::Property.first.name.should == "new name"
      end

      it 'does not sync changes that happened a while before the last seen change' do
        property = Property.create!(:name => "old name")
        subject.sync
        Timecop.freeze(Time.current - 60.minutes) do
          property.name = "new name"
          property.save(false)
          set_row_touched_at(property)
        end
        subject.sync
        DataTieringSyncSpec::Property.first.name.should == "old name"
      end

      it 'syncs new properties' do
        Property.create!(:name => "property 1")
        subject.sync
        Property.create!(:name => "property 2")
        subject.sync
        DataTieringSyncSpec::Property.count.should == 2
      end

      it 'syncs changed properties' do
        property = Property.create!(:name => "old name")
        subject.sync
        property.name = "new name"
        property.save(false)
        subject.sync
        DataTieringSyncSpec::Property.first.name.should == "new name"
      end

      it 'syncs deletions, but does not touch the regular table' do
        Property.create!(:name => "property 1")
        property = Property.create!(:name => "property 2")
        subject.sync

        property.delete

        expect { subject.sync }.to change(DataTieringSyncSpec::Property, :count).by(-1)
      end

      context "batch processing" do

        let!(:property1) { Property.create!(:name => "Hello") }
        let!(:property2) {
          property = Property.create!(:name => "World!")
          # We need to manually set the id to 100 so batches can work
          ::ActiveRecord::Base.connection.execute("UPDATE `properties` SET `id`='101' WHERE `id` = '#{property.id}'")
          Property.find(101)
        }

        before do
          @original_batch_size = DataTiering.configuration.batch_size
          DataTiering.configuration.batch_size = 100
        end

        after do
          DataTiering.configuration.batch_size = @original_batch_size
        end

        context 'when more than one batch' do
          before { subject.sync }

          it 'copies all properties' do
            DataTieringSyncSpec::Property.all.collect(&:id).should =~ [property1.id, property2.id]
          end

          it 'deletes properties' do
            Property.find(property2.id).delete
            subject.sync

            DataTieringSyncSpec::Property.all.collect(&:id).should =~ [property1.id]
          end
        end

        it 'only takes timestamps from an already processed batch' do
          Timecop.freeze(1.month.from_now) do
            Property.find(property1.id).save(false)
          end

          subject.sync
          DataTieringSyncSpec::Property.all.collect(&:id).should =~ [property1.id, property2.id]
        end

        it 'performs only one insert per batch' do
          DataTiering::Sync::SyncLog.stub(:log).and_yield
          ActiveRecord::Base.connection.should_receive(:insert).exactly(:twice)
          subject.sync
        end

        it 'performs only one delete per batch' do
          subject.sync
          Property.delete_all
          DataTiering::Sync::SyncLog.stub(:log).and_yield

          ActiveRecord::Base.connection.should_receive(:delete).exactly(:twice)
          subject.sync
        end

      end

    end

  end

  describe '#with_transaction_isolation_level' do

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
