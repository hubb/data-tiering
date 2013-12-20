# encoding: UTF-8

lib = File.expand_path('lib')
$:.unshift(lib) unless $:.include?(lib)

require 'data_tiering/configuration'

module DataTiering
  VERSION = '0.0.2'

  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end
end

# require 'data_tiering/sync'
