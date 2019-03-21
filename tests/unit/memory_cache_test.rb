require_relative "../minitest_helper"

module GraphiteAPI
  class MemoryCacheTester < Unit::TestCase

    def test_set_and_get
      cache.tap do |obj|
        obj.set(1, :tuki, "1")
        assert_equal "1", obj.get(1, :tuki)

        obj.set(1, :tuki, 1.12)
        assert_equal 1.12, obj.get(1, :tuki)

        obj.set(1, :tuki, "1.12")
        
        assert_equal "1.12", obj.get(1, :tuki)
        assert_equal "1.12", obj.get(1, :tuki)
        assert_equal "1.12", obj.get(1, :tuki)
        assert_nil obj.get(2, :blablabla)
      end
    end
    
    def test_clean
      cache.tap do |obj|
        time = Time.now.to_i - 60
        obj.set(time,:shuki,10)
        assert_equal 10, obj.get(time, :shuki)
        
        obj.__send__(:clean,60)
        assert_equal 10, obj.get(time, :shuki)
        
        obj.__send__(:clean,59)
        assert_nil obj.get(time, :shuki)
      end
    end
    
    private

    def cache
      # Zscheduler.expects(:every).with(120)
      Cache::Memory.new(:options)
    end
  end
end
