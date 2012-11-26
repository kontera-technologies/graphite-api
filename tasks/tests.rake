require "rake/testtask"

task(:test) { ENV['with_coverage'] = "true" }

Rake::TestTask.new(:test) do |t|
  t.libs << "tests"
  t.pattern = "tests/**/*_test.rb"
end

task :default => :test