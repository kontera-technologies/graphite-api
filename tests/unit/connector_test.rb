require_relative "../minitest_helper"

module GraphiteAPI
  class ConnectorTester < Unit::TestCase

    def test_right_socket_class
      Connector.new("udp://graphite:1234").tap do |obj|
        assert_kind_of Connector::UDPSocket, obj.send(:socket)
      end
      Connector.new("tcp://shuki:1234").tap do |obj|
        assert_kind_of Connector::TCPSocket, obj.send(:socket)
      end
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
