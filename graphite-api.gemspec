lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graphite-api/version'

Gem::Specification.new do |s|
  s.name                  = "graphite-api"
  s.version               = GraphiteAPI::VERSION
  s.platform              = Gem::Platform::RUBY
  s.summary               = "Graphite Ruby Client"
  s.description           = "Graphite API - A Simple ruby client, aggregator daemon and API tools"
  s.author                = "Eran Barak Levi"
  s.email                 = 'eran@kontera.com'
  s.homepage              = 'http://www.kontera.com'
  s.license               = 'LGPL-3.0'
  s.required_ruby_version = '>= 2.3'
  s.files                 = %w(LICENSE README.md Rakefile) + Dir.glob("{lib,test,tasks}/**/*")
  s.require_path          = "lib"

  s.add_runtime_dependency 'timers', '~> 4.3'
  s.add_runtime_dependency 'jruby-openssl' if RUBY_PLATFORM == 'java'

  s.add_development_dependency 'rake', '>= 0.9.2.2'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'eventmachine'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'codecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'gem-release', '~> 2.0'
end
