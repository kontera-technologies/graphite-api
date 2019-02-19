$:.unshift File.join(File.dirname(__FILE__), 'lib')
Dir.chdir File.dirname __FILE__

require 'graphite-api'
require "rake/testtask"
require 'rubygems/package_task'

def message msg
  puts "*** #{msg} ***"
end

task(:test => :functional)

Rake::TestTask.new do |t|
  t.libs << "tests"
  t.pattern = "tests/**/*_test.rb"
end

task :functional do
  some_failed = false

  next unless ENV['SKIP_FUNC'].nil?

  unless RUBY_COPYRIGHT.end_with?("Matsumoto")
    puts("Functional tests are enabled only on MRI...")
    next
  end

  message "Executing GraphiteAPI Functional Tests"
  message "( You can skip them by passing SKIP_FUNC=true )"

  Dir[File.expand_path("../tests/functional/*",__FILE__)].each do |file|
    next unless file.end_with?(".rb")
    now = Time.now.to_i
    name = File.basename(file)
    message "Executing #{name}"
    Process.waitpid(Process.spawn("ruby", File.expand_path(file)))
    took = "took #{Time.now.to_i - now} seconds"
    if $?.success?
      message "[PASS] #{name}, #{took}"
    else
      message "[FAIL] #{name}, #{took}"
      some_failed = true
    end
  end
  message "Done Executing GraphiteAPI Functional Tests"
  abort "Some functional tests failed..." if some_failed
end

task :default => :test

task :gem => [:test,:clobber_package]

GraphiteAPI::GemSpec = eval File.read 'graphite-api.gemspec'

Gem::PackageTask.new(GraphiteAPI::GemSpec) do |p|
  p.gem_spec = GraphiteAPI::GemSpec
end
