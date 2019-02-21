require_relative "../minitest_helper"
require 'eventmachine'

module GraphiteAPI
  class ClientSanityTester < Unit::TestCase
    TCP_PORT = 9875
    UDP_PORT = 9876

    def setup
      @tcp_data = []
      @udp_data = []
    end

    def test_clients_with_avg_aggregation
      EventMachine.run {
        start_servers
        clients(:default_aggregation_method => :avg).each { |client|
          1.upto(1000) do
            client.metrics({"default.foo" => 20}, Time.at(123456789))
            client.metrics({"default.foo" => 31}, Time.at(123456789))
          end
          EventMachine::Timer.new(2,&EM.method(:stop))
        }
      }

      assert_expected_equals_data ["default.foo 25.5 123456780"]
    end

    def test_clients_with_replace_aggregation
      EventMachine.run {
        start_servers
        clients(:default_aggregation_method => :replace).each { |client|
          1.upto(1000) do
            client.metrics({"default.foo" => 20}, Time.at(123456789))
            client.metrics({"default.foo" => 40}, Time.at(123456789))
          end
          EventMachine::Timer.new(2,&EM.method(:stop))
        }
      }

      assert_expected_equals_data ["default.foo 40.0 123456780"]
    end

    def test_clients_with_default_options
      EventMachine.run {
        start_servers
        clients.each { |client|
          1.upto(1000) do
            client.metrics({"default.foo" => 10, "default.bar" => 5}, Time.at(123456789))
            client.metrics({"sum.qux" => 20}, Time.at(123456789), :sum)

            client.metrics({"avg.foo" => 1.0}, Time.at(123456789), :avg)
            client.metrics({"avg.foo" => 1.2}, Time.at(123456789), :avg)

            client.metrics({"replace.foo" => 5}, Time.at(123456789), :replace)
            client.metrics({"replace.foo" => 10}, Time.at(123456789), :replace)
          end
          EventMachine::Timer.new(2,&EM.method(:stop))
        }
      }

      expected = [
        "default.foo 10000.0 123456780",
        "default.bar 5000.0 123456780",
        "sum.qux 20000.0 123456780",
        "avg.foo 1.1 123456780",
        "replace.foo 10.0 123456780",
      ]
      assert_expected_equals_data expected
    end

    def start_servers
      EventMachine.start_server("0.0.0.0", TCP_PORT, MockServer, @tcp_data)
      EventMachine.open_datagram_socket("0.0.0.0", UDP_PORT, MockServer, @udp_data)
    end

    def clients opts={}
      [
        GraphiteAPI.new({graphite: "tcp://localhost:#{TCP_PORT}", interval: 2}.merge(opts)),
        GraphiteAPI.new({graphite: "udp://localhost:#{UDP_PORT}", interval: 2}.merge(opts))
      ]
    end

    def assert_expected_equals_data expected
      sleep 4 # Removing this will fail the test with --seed=48010
      assert_equal expected.sort, @tcp_data.map {|x| x.split("\n")}.flatten.sort
      assert_equal expected.sort, @udp_data.map {|x| x.split("\n")}.flatten.sort
    end
  end
end
