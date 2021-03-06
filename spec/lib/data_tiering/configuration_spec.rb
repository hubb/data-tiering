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

    it 'configures size of batch to sync' do
      subject.batch_size = 30
      expect(subject.batch_size).to eql(30)
    end

    context 'models to sync' do

      it 'accepts model names as strings' do
        subject.models_to_sync = ['Property']
        expect(subject.models_to_sync).to eq([Property])
      end

    end

    context 'cache' do
      let(:cache) { proc { 'yay!' } }

      it 'invokes the proc if a proc is given' do
        subject.cache = cache
        cache.should_receive(:call).and_call_original

        subject.cache.should eql('yay!')
      end

      it 'returns the cache if it\'s not a proc' do
        subject.cache = 'yay'
        cache.should_not_receive :call

        subject.cache.should eql('yay')
      end
    end
  end
end
