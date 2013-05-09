require 'rubygems/package_task'

GraphiteAPI::GemSpec = Gem::Specification.new do |s|
  s.name                  = "graphite-api"
  s.version               = GraphiteAPI.version
  s.platform              = Gem::Platform::RUBY
  s.summary               = "Graphite Ruby Client"
  s.description           = "Graphite API - A Simple ruby client, aggregator daemon and API tools"
  s.author                = "Eran Barak Levi"
  s.email                 = 'eran@kontera.com'
  s.homepage              = 'http://www.kontera.com'
  s.executables           = %w(graphite-middleware)
  s.required_ruby_version = '>= 1.8.7'
  s.rubyforge_project     = "graphite-api"
  s.files                 = %w(README.md Rakefile) + Dir.glob("{bin,lib,test,tasks}/**/*")
  s.require_path          = "lib"
  s.bindir                = "bin"

  s.add_dependency 'eventmachine','>= 0.3.3'
  s.add_dependency 'zscheduler',  '>= 0.0.3'
end

task :gem => [:test,:clobber_package]

Gem::PackageTask.new(GraphiteAPI::GemSpec) do |p|
  p.gem_spec = GraphiteAPI::GemSpec
end

task :install => [:gem] do
   sh "gem install pkg/graphite-api"
   Rake::Task['clobber_package'].execute
end
