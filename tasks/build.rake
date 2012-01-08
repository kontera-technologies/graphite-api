require 'rubygems/package_task'

GraphiteAPI::GemSpec = Gem::Specification.new do |s|
  s.name                  = "graphite-api"
  s.version               = GraphiteAPI.version
  s.platform              = Gem::Platform::RUBY
  s.summary               = "GraphiteAPI"
  s.description           = "GraphiteAPI - Graphite API tools"
  s.author                = "Eran Levi"
  s.email                 = 'eran@kontera.com'
  s.homepage              = 'http://www.kontera.com'
  s.executables           = %w(graphite-middleware)
  s.required_ruby_version = '>= 1.8.7'
  s.rubyforge_project     = "graphite-api"
  s.files                 = %w(README.rdoc Rakefile) + Dir.glob("{bin,lib,test,tasks}/**/*")
  s.require_path          = "lib"
  s.bindir                = "bin"

  s.add_dependency 'eventmachine','>= 0.3.3'
end

task :gem => [:clobber_package]
Gem::PackageTask.new(GraphiteAPI::GemSpec) do |p|
  p.gem_spec = GraphiteAPI::GemSpec
end

namespace :gem do
  desc "Update GraphiteAPI gem version"
  task :update_version do
    GraphiteAPI::Version.increment_pre
    msg "Incrementing version to #{GraphiteAPI::Version.string}..."
  end
  
  desc "Upload GraphiteAPI to Kontera's repo"
  task :upload => [:build] do
    sh "gem inabox --host http://gems.kontera.com pkg/graphite-api-#{GraphiteAPI.version}.gem"
  end
  
  desc "Update GraphiteAPI gem version and build gem"
  task :build => [:test,:update_version] do
    sh "rake gem"
  end 
  
end