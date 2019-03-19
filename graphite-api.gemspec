$:.unshift File.expand_path('../lib',__FILE__)

require 'graphite-api'

Gem::Specification.new do |s|
  s.name                  = "graphite-api"
  s.version               = GraphiteAPI.version
  s.platform              = Gem::Platform::RUBY
  s.summary               = "Graphite Ruby Client"
  s.description           = "Graphite API - A Simple ruby client, aggregator daemon and API tools"
  s.author                = "Eran Barak Levi"
  s.email                 = 'eran@kontera.com'
  s.homepage              = 'http://www.kontera.com'
  s.license               = 'LGPL-3.0'
  s.required_ruby_version = '>= 2.3'
  s.rubyforge_project     = "graphite-api"
  s.files                 = %w(LICENSE README.md Rakefile) + Dir.glob("{lib,test,tasks}/**/*")
  s.require_path          = "lib"

  s.add_dependency 'eventmachine','>= 0.3.3'
  s.add_dependency 'zscheduler',  '>= 0.0.7'
end
