require 'spec_helper'

shared_examples_for "a model that is part of data tiering" do

  describe '#row_touched_at' do

    it 'complains when being read' do
      proc do
        described_class.new.row_touched_at
      end.should raise_error("this is a MySQL timestamp, don't use it as an AR attribute")
    end

    it 'does not allow accidental overridding via mass assignment' do
      t = Time.zone.parse("2013-01-01 12:00")
      model = described_class.create!(:row_touched_at => t)
      model.attributes = { :row_touched_at => t + 1.year }
      model.read_attribute(:row_touched_at).should == t
    end

  end

end

class Property < ::ActiveRecord::Base; end

describe Property do

  it_should_behave_like "a model that is part of data tiering"

end

# describe Availability do

#   it_should_behave_like "a model that is part of data tiering"

# end

# describe Rate do

#   it_should_behave_like "a model that is part of data tiering"

# end
