$:.unshift File.join(File.dirname(__FILE__), 'lib')
Dir.chdir File.dirname __FILE__

require 'graphite-api'

def message msg
  puts "*** #{msg} ***"
end

Dir['tasks/**/*.rake'].each { |rake| load rake }