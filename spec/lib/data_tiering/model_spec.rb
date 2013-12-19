require 'spec_helper'

shared_examples_for "a model that is part of data tiering" do

  describe '#row_touched_at' do

    let(:time) { Time.parse("12pm 1st January 2013") }

    it 'raises an error when being read' do
      expect {
        described_class.new.row_touched_at
      }.to raise_error("this is a MySQL timestamp, don't use it as an AR attribute")
    end

    it 'allows direct attribute assignment on row_touched_at' do
      subject.row_touched_at = time
      subject.save!

      expect(subject.read_attribute(:row_touched_at)).to eql(time)
    end

    it 'does not allow mass assignment on creation' do
      instance = described_class.create!(:row_touched_at => time)
      instance.read_attribute(:row_touched_at).should be_nil
    end

    it 'does not allow mass assignment on attributes change' do
      subject.row_touched_at = time
      subject.attributes = { :row_touched_at => time + 1.year }
      subject.read_attribute(:row_touched_at).should == time
    end

  end

end

describe Property do

  it_should_behave_like "a model that is part of data tiering"

end

# describe Availability do

#   it_should_behave_like "a model that is part of data tiering"

# end

# describe Rate do

#   it_should_behave_like "a model that is part of data tiering"

# end
