require 'spec_helper'

describe DataTiering::Configuration do
  it 'provides default values for configuration options' do
    subject.search_enabled.should be_true
    subject.sync_enabled.should be_true
    subject.models_to_sync.should == []
  end

  it 'allows configuration options to be changed' do
    subject.search_enabled = false
    subject.search_enabled.should be_false

    subject.sync_enabled = false
    subject.sync_enabled.should be_false

    subject.models_to_sync = [1,2,3]
    subject.models_to_sync.should == [1,2,3]
  end
end
