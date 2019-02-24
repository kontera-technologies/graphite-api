require_relative "../minitest_helper"
require 'eventmachine'
require 'socket'

module GraphiteAPI
  class MiddlewareSanityTester < Unit::TestCase
    EM_STOP_AFTER = 4
    MIDDLEWARE_BIN_FILE = File.expand_path("../../../bin/graphite-middleware", __FILE__)

    def setup
      @middleware_port = Random.rand(1000..4999)
      @mock_server_port = Random.rand(5000..9999)
      @data = []
    end

    def test_with_defaults
      options = %W(--port #{@middleware_port} --graphite tcp://localhost:#{@mock_server_port} --interval 2 -L error)
      pid = Process.spawn("ruby", MIDDLEWARE_BIN_FILE, *options)
      sleep 1
      EventMachine.run {
        EventMachine.start_server("0.0.0.0", @mock_server_port, MockServer, @data)
        socket = TCPSocket.new("0.0.0.0",@middleware_port)
        1.upto(1000) do
          socket.puts("shuki.tuki1 1.1 123456789\n")
          socket.puts("shuki.tuki2 10 123456789\n")
          socket.puts("shuki.tuki3 10 123456789\n")
        end
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
      options = %W(--port #{@middleware_port} --graphite tcp://localhost:#{@mock_server_port} --aggregation-method avg --interval 2 -L error)
      pid = Process.spawn("ruby", MIDDLEWARE_BIN_FILE, *options)
      sleep 1
      EventMachine.run {
        EventMachine.start_server("0.0.0.0", @mock_server_port, MockServer, @data)
        socket = TCPSocket.new("0.0.0.0",@middleware_port)
        1.upto(1000) do
          socket.puts("shuki.tuki1 1.0 123456789\n")
          socket.puts("shuki.tuki1 1.2 123456789\n")
        end
      }

      assert_expected_equals_data ["shuki.tuki1 1.1 123456780"]
    ensure
      Process.kill(:KILL, pid)
    end

    def test_with_replace
      options = %W(--port #{@middleware_port} --graphite tcp://localhost:#{@mock_server_port} --aggregation-method replace --interval 2 -L error)
      pid = Process.spawn("ruby", MIDDLEWARE_BIN_FILE, *options)
      sleep 1
      EventMachine.run {
        EventMachine.start_server("0.0.0.0", @mock_server_port, MockServer, @data)
        socket = TCPSocket.new("0.0.0.0",@middleware_port)
        1.upto(1000) do
          socket.puts("shuki.tuki1 10.0 123456789\n")
          socket.puts("shuki.tuki1 5.0 123456789\n")
        end
      }

      assert_expected_equals_data ["shuki.tuki1 5.0 123456780"]
    ensure
      Process.kill(:KILL, pid)
    end

    def assert_expected_equals_data expected
      sleep EM_STOP_AFTER # Removing this will fail the test with --seed=48010
      assert_equal expected, @data.map {|o| o.split("\n")}.flatten(1).map(&:strip)
    end
  end
end
