$:.unshift File.join(File.dirname(__FILE__), 'lib')
Dir.chdir File.dirname __FILE__

require 'graphite-api'

Dir['tasks/**/*.rake'].each { |rake| load rake }