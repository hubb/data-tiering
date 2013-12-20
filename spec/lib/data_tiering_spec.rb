require 'spec_helper'

describe DataTiering do
  subject { DataTiering }

  describe '#configure' do
    it 'yields the current configuration' do
      subject.configure do |config|
        expect(config).to equal(subject.configuration)
      end
    end

    it 'allows you to configure options to the yielded configuration' do
      config = Struct.new(:an_option).new(:an_option => 'not configured')
      subject.stub(:configuration).and_return(config)

      subject.configure do |config|
        config.an_option = 'configured!'
      end

      expect(config.an_option).to eq('configured!')
    end
  end
end
