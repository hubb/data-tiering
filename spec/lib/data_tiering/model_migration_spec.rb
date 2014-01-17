require 'spec_helper'

class Sample < ActiveRecord::Base; end;
class CreateSamples < ActiveRecord::Migration
  def self.up
    create_table :samples
  end

  def self.down
    drop_table :samples
  end
end

describe DataTiering::ModelMigration do
  subject { Class.new(ActiveRecord::Migration).extend(described_class) }

  it "is an active record migration" do
    subject.ancestors.should include(ActiveRecord::Migration)
  end

  describe "#up" do
    before do
      CreateSamples.up
      subject.table_name = 'samples'
    end

    after do
      CreateSamples.down
    end

    it "applies cleanly" do
      expect {
        silence_stream(STDOUT) { subject.up }
      }.not_to raise_error
      Sample.new.attributes.should include("row_touched_at")
    end

    it "alters the configured table_name" do
      subject.table_name = 'hello'

      expect {
        subject.up
      }.to raise_error(/Table .+hello.+ doesn't exist/)
    end

    it "raises an error if table_name is not configured" do
      subject.table_name = nil

      expect {
        subject.up
      }.to raise_error(/table_name cannot be blank\./)
    end
  end
end
