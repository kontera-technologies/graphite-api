
$:.unshift File.expand_path("../../../lib", __FILE__)

require 'graphite-api'
require 'eventmachine'

module CarboonD
  def initialize data
    @data = data
  end

  def receive_data data
    @data.push data
  end
end

port = 9877
data_tcp = []
data_udp = []

EventMachine.run {
  EventMachine.start_server("0.0.0.0", port, CarboonD, data_tcp)
  EventMachine.open_datagram_socket("0.0.0.0", port, CarboonD, data_udp)

  tcp_client = GraphiteAPI.new graphite: "tcp://localhost:#{port}", interval: 2
  udp_client = GraphiteAPI.new graphite: "udp://localhost:#{port}", interval: 2

  1.upto(1000) do
    [tcp_client, udp_client].each do |client|
      client.metrics({"shuki.tuki1" => 1.0}, Time.at(123456789), :avg)
      client.metrics({"shuki.tuki1" => 1.2}, Time.at(123456789), :avg)

      client.metrics({"shuki.tuki2" => 10}, Time.at(123456789))

      client.metrics({"shuki.tuki3" => 5}, Time.at(123456789), :replace)
      client.metrics({"shuki.tuki3" => 10}, Time.at(123456789), :replace)
    end
  end

  EventMachine::PeriodicTimer.new(5,&EM.method(:stop))
}

sleep 5

expected = [
  "shuki.tuki1 1.1 123456780",
  "shuki.tuki2 10000.0 123456780",
  "shuki.tuki3 10.0 123456780"
].sort

actual_tcp = data_tcp.map {|x| x.split("\n")}.flatten.sort
actual_udp = data_udp.map {|x| x.split("\n")}.flatten.sort

if actual_tcp != expected
  STDERR.puts "TCP client: actual not equal to expected."
  STDERR.puts "Actual: #{actual_tcp.inspect}"
  STDERR.puts "Expected: #{expected.inspect}"
  exit 1
end

if actual_udp != expected
  STDERR.puts "UDP client: actual not equal to expected."
  STDERR.puts "Actual: #{actual_udp.inspect}"
  STDERR.puts "Expected: #{expected.inspect}"
  exit 1
end
