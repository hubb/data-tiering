# encoding: UTF-8

lib = File.expand_path('lib')
$:.unshift(lib) unless $:.include?(lib)

require 'data_tiering/configuration'
require 'data_tiering/setup_migration'
require 'data_tiering/model_migration'

module DataTiering
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end
end
