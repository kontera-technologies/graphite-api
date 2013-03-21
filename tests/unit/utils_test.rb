require_relative "../minitest_helper"

module GraphiteAPI
  class UtilsTester < Unit::TestCase
    def test_expand_host
      assert_equal ["localhost", 2003], Utils.expand_host("localhost")
      assert_equal ["localhost", 1234], Utils.expand_host("localhost:1234")
      assert_equal ["www.shuki.com", 2003], Utils.expand_host("graphite://www.shuki.com/sal")
      assert_equal ["www.shuki.com", 9876], Utils.expand_host("graphite://www.shuki.com:9876/sal")
    end
  end
end
