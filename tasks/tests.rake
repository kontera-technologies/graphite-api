require "rake/testtask"

task(:test => :functional) { ENV['with_coverage'] = "true" }

Rake::TestTask.new(:test) do |t|
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

  Dir[File.expand_path("../../tests/functional/*",__FILE__)].each do |file|
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