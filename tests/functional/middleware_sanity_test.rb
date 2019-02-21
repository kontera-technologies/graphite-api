require_relative "../minitest_helper"
require 'eventmachine'
require 'socket'

module GraphiteAPI
  MIDDLEWARE_PORT = 9141
  MOCK_SERVER_PORT = 9876
  MIDDLEWARE_BIN_FILE = File.expand_path("../../../bin/graphite-middleware", __FILE__)
  class MiddlewareSanityTester < Unit::TestCase
    def setup
      @data = []
    end

    def test_with_defaults
      options = %W(--port #{MIDDLEWARE_PORT} --graphite tcp://localhost:#{MOCK_SERVER_PORT} --interval 2 -L error)
      pid = Process.spawn("ruby", MIDDLEWARE_BIN_FILE, *options)
      sleep 1
      EventMachine.run {
        EventMachine.start_server("0.0.0.0", MOCK_SERVER_PORT, MockServer, @data)
        socket = TCPSocket.new("0.0.0.0",MIDDLEWARE_PORT)
        1.upto(1000) do
          socket.puts("shuki.tuki1 1.1 123456789\n")
          socket.puts("shuki.tuki2 10 123456789\n")
          socket.puts("shuki.tuki3 10 123456789\n")
        end
        EventMachine::Timer.new(4, &EM.method(:stop))
      }

      expected = [
        "shuki.tuki1 1100.0 123456780",
        "shuki.tuki2 10000.0 123456780",
        "shuki.tuki3 10000.0 123456780"
      ]
      assert_expected_equals_data expected
    ensure
      Process.kill(:KILL, pid)
    end

    def test_with_avg
      options = %W(--port #{MIDDLEWARE_PORT} --graphite tcp://localhost:#{MOCK_SERVER_PORT} --aggregation-method avg --interval 2 -L error)
      pid = Process.spawn("ruby", MIDDLEWARE_BIN_FILE, *options)
      sleep 1
      EventMachine.run {
        EventMachine.start_server("0.0.0.0", MOCK_SERVER_PORT, MockServer, @data)
        socket = TCPSocket.new("0.0.0.0",MIDDLEWARE_PORT)
        1.upto(1000) do
          socket.puts("shuki.tuki1 1.0 123456789\n")
          socket.puts("shuki.tuki1 1.2 123456789\n")
        end
        EventMachine::Timer.new(4, &EM.method(:stop))
      }

      assert_expected_equals_data ["shuki.tuki1 1.1 123456780"]
    ensure
      Process.kill(:KILL, pid)
    end

    def test_with_replace
      options = %W(--port #{MIDDLEWARE_PORT} --graphite tcp://localhost:#{MOCK_SERVER_PORT} --aggregation-method replace --interval 2 -L error)
      pid = Process.spawn("ruby", MIDDLEWARE_BIN_FILE, *options)
      sleep 1
      EventMachine.run {
        EventMachine.start_server("0.0.0.0", MOCK_SERVER_PORT, MockServer, @data)
        socket = TCPSocket.new("0.0.0.0",MIDDLEWARE_PORT)
        1.upto(1000) do
          socket.puts("shuki.tuki1 10.0 123456789\n")
          socket.puts("shuki.tuki1 5.0 123456789\n")
        end
        EventMachine::Timer.new(4, &EM.method(:stop))
      }

      assert_expected_equals_data ["shuki.tuki1 5.0 123456780"]
    ensure
      Process.kill(:KILL, pid)
    end

    def assert_expected_equals_data expected
      assert_equal expected, @data.map {|o| o.split("\n")}.flatten(1).map(&:strip)
    end
  end
end
