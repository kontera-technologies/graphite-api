$:.unshift File.join(File.dirname(__FILE__), 'lib')
Dir.chdir File.dirname __FILE__

require 'graphite-api'
require 'bundler/setup'

def msg m
  $stderr.puts "[*] #{m}"
end

Dir['tasks/**/*.rake'].each { |rake| load rake }