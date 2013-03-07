require_relative "../minitest_helper"

module GraphiteAPI
  class ConnectorTester < Unit::TestCase
    def test_initialize
      Connector.new(:host,:port).tap do |obj|
        assert_equal :host, obj.instance_variable_get(:@host)
        assert_equal :port, obj.instance_variable_get(:@port)
      end
    end
    
    def test_puts
      Connector.new(:host,:port).tap do |obj|
        socket = mock { expects(:puts).with("message\n")}
        obj.expects(:socket).returns(socket)
        obj.puts "message"
      end
    end
    
  end
end
