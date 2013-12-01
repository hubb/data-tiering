# encoding: UTF-8

lib = File.expand_path('lib')
$:.unshift(lib) unless $:.include?(lib)

require 'data_tiering'

Gem::Specification.new do |s|
  s.name        = 'data_tiering'
  s.version     = DataTiering::VERSION
  s.authors     = ['Tobias Kraze', 'Julien Letessier', 'Thibault Gautriaud']
  s.email       = ['tobias@kraze.de', 'jletessier@housetrip.com', 'hubbbbb@gmail.com']
  s.homepage    = 'https://github.com/hubb/data_tiering'
  s.summary     = 'Segregate data into read-mostly and write-mostly'
  s.description = 'Segregate data into read-mostly and write-mostly'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-nav'

  s.files        = `git ls-files`.split('\n')
  s.test_files   = `git ls-files -- spec/*/*_spec*`.split('\n')
  s.require_path = 'lib'
end
