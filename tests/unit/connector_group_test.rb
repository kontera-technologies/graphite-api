require_relative "../minitest_helper"

module GraphiteAPI
  class ConnectorGroupTester < Unit::TestCase
    def test_initialize
      Connector.expects(:new).with(:backend1).returns(:backend1)
      Connector.expects(:new).with(:backend2).returns(:backend2)
      Connector.expects(:new).with(:backend3).returns(:backend3)
      obj = ConnectorGroup.new(:backends => [:backend1, :backend2, :backend3])
      assert_equal [:backend1, :backend2, :backend3], obj.instance_variable_get(:@connectors)
    end
    
    def test_pushlish
      Connector.expects(:new).with(:backend1).returns(mock { expects(:puts).with(:shuki) })
      Connector.expects(:new).with(:backend2).returns(mock { expects(:puts).with(:shuki) })
      Connector.expects(:new).with(:backend3).returns(mock { expects(:puts).with(:shuki) })
      ConnectorGroup.new(:backends => [:backend1, :backend2, :backend3]).publish(:shuki)
    end
  end
end