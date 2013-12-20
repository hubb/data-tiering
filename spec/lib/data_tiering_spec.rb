require 'spec_helper'

describe DataTiering do
  subject { DataTiering }

  describe '#configure' do
    it 'yields the current configuration' do
      subject.configure do |config|
        expect(config).to equal(subject.configuration)
      end
    end

    let(:config) { Struct.new(:an_option).new(:an_option => 'not configured') }

    it 'allows to configure options' do
      subject.stub(:configuration).and_return(config)

      subject.configure do |config|
        config.an_option = 'configured!'
      end

      expect(config.an_option).to eq('configured!')
    end
  end
end
