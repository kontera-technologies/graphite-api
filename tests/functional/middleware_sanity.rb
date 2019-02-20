$:.unshift File.expand_path("../../../lib", __FILE__)

Dir.chdir File.dirname __FILE__

require 'socket'
require 'graphite-api'
require 'eventmachine'
require 'fileutils'

module FakeCarboonDaemon
  def initialize data
    @data = data
  end

  def receive_data data
    @data.push data
  end
end

middleware_port  = 9141
fake_carbon_port = 9876
middleware_log_file = File.expand_path("../../../middleware.out",__FILE__)

File.new(middleware_log_file,'w').close

options = %W(--port #{middleware_port} --graphite tcp://localhost:#{fake_carbon_port} --interval 10 -L debug -l #{middleware_log_file})

pid = Process.spawn("ruby", "./../../bin/graphite-middleware", *options)

sleep 5

begin
  data = []
  EventMachine.run {
    EventMachine.start_server("0.0.0.0", fake_carbon_port, FakeCarboonDaemon, data)

    socket = TCPSocket.new("0.0.0.0",middleware_port)

    1.upto(1000) do
      socket.puts("shuki.tuki1 1.1 123456789\n")
      socket.puts("shuki.tuki2 10 123456789\n")
      socket.puts("shuki.tuki3 10 123456789\n")
    end

    EventMachine::PeriodicTimer.new(10,&EM.method(:stop))
  }

  expected = [
    "shuki.tuki1 1100.0 123456780",
    "shuki.tuki2 10000.0 123456780",
    "shuki.tuki3 10000.0 123456780"
  ]
  if expected == data.map {|o| o.split("\n")}.flatten(1).map(&:strip)
    FileUtils.rm_rf middleware_log_file
  else
    STDERR.puts "#{data.inspect} != #{expected.inspect}"
    STDERR.puts "GraphiteAPI::Middleware logfile @#{middleware_log_file}"
    exit(1)
  end
ensure
  Process.kill(:KILL, pid)
end
