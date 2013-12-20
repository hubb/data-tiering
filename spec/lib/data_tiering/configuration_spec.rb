require 'spec_helper'

describe DataTiering::Configuration do
  it 'provides default values for configuration options' do
    expect(subject.search_enabled).to be_true
    expect(subject.sync_enabled).to be_true
    expect(subject.models_to_sync).to eq([])
  end

  it 'allows configuration options to be changed' do
    subject.search_enabled = false
    expect(subject.search_enabled).to be_false

    subject.sync_enabled = false
    expect(subject.sync_enabled).to be_false

    subject.models_to_sync = [1,2,3]
    expect(subject.models_to_sync).to eq([1,2,3])
  end
end
