require_relative "../minitest_helper"
require 'socket'

module GraphiteAPI
  class ConnectorTester < Unit::TestCase

    def test_right_socket_class
      Connector.new("udp://localhost:1234").tap do |obj|
        assert_kind_of UDPSocket, obj.send(:socket)
      end
    end

    def test_should_throw_exception_invalid_host
      Connector.new("udp://hihi:1111").tap {|x| assert_raises(SocketError,&x.method(:check!))}
      Connector.new("tcp://hihi:1111").tap {|x| assert_raises(SocketError,&x.method(:check!))}
    end

    def test_puts
      Connector.new("shuki").tap do |obj|
        socket = mock { expects(:puts).with("message\n")}
        obj.expects(:socket).returns(socket)
        obj.puts "message"
      end
    end

  end
end
