require 'spec_helper'

describe DataTiering::Configuration do
  describe 'default values' do
    it 'search is enabled' do
      expect(subject.search_enabled).to be_true
    end

    it 'sync is enabled' do
      expect(subject.sync_enabled).to be_true
    end

    it 'models_to_sync is empty' do
      expect(subject.models_to_sync).to eq([])
    end

    it 'batch_size is 100_000' do
      expect(subject.batch_size).to eql(100_000)
    end
  end

  describe 'configuring' do
    it 'search can be disabled' do
      subject.search_enabled = false
      expect(subject.search_enabled).to be_false
    end

    it 'sync can be disabled' do
      subject.sync_enabled = false
      expect(subject.sync_enabled).to be_false
    end

    it 'configures models to sync' do
      subject.models_to_sync = [1,2,3]
      expect(subject.models_to_sync).to eq([1,2,3])
    end

    it 'configures size of batch to sync' do
      subject.batch_size = 30
      expect(subject.batch_size).to eql(30)
    end
  end
end
