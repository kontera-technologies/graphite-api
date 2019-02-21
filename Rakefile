$:.unshift File.join(File.dirname(__FILE__), 'lib')
Dir.chdir File.dirname __FILE__

require 'graphite-api'
require "rake/testtask"
require 'rubygems/package_task'

Rake::TestTask.new(:prepare) do |t|
  t.libs << "tests"
end

Rake::TestTask.new(:unit => :prepare) do |t|
  t.pattern = "tests/unit/*_test.rb"
end

Rake::TestTask.new(:functional => :prepare) do |t|
  t.pattern = "tests/functional/*_test.rb"
end

task(:test => [:unit, :functional])

task :default => :test

task :gem => [:test, :clobber_package]

GraphiteAPI::GemSpec = eval File.read 'graphite-api.gemspec'

Gem::PackageTask.new(GraphiteAPI::GemSpec) do |p|
  p.gem_spec = GraphiteAPI::GemSpec
end
