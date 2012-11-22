require_relative "../minitest_helper"

module GraphiteAPI
  class CoreExtensionsTester < ::MiniTest::Unit::TestCase
    
    def test_number_should_act_like_a_year_duration
      assert_equal 1.year,  365 * 24 * 3600
      assert_equal 2.year,  365 * 24 * 3600 * 2
      assert_equal 3.years, 365 * 24 * 3600 * 3
      
      assert_equal 1.0.year,  365 * 24 * 3600
      assert_equal 2.0.year,  365 * 24 * 3600 * 2
      assert_equal 3.0.years, 365 * 24 * 3600 * 3
    end
    
    def test_number_should_act_like_a_month_duration
      assert_equal 1.month,  30 * 24 * 3600
      assert_equal 2.month,  30 * 24 * 3600 * 2
      assert_equal 3.months, 30 * 24 * 3600 * 3
      
      assert_equal 1.0.month,  30 * 24 * 3600
      assert_equal 2.0.month,  30 * 24 * 3600 * 2
      assert_equal 3.0.months, 30 * 24 * 3600 * 3
    end
    
    def test_number_should_act_like_a_week_duration
      assert_equal 1.week,  7 * 24 * 3600
      assert_equal 2.week,  7 * 24 * 3600 * 2
      assert_equal 3.weeks, 7 * 24 * 3600 * 3
      
      assert_equal 1.0.week,  7 * 24 * 3600
      assert_equal 2.0.week,  7 * 24 * 3600 * 2
      assert_equal 3.0.weeks, 7 * 24 * 3600 * 3
    end

    def test_number_should_act_like_a_day_duration
      assert_equal 1.day,  24 * 3600
      assert_equal 2.day,  24 * 3600 * 2
      assert_equal 3.days, 24 * 3600 * 3
      
      assert_equal 1.0.day,  24 * 3600
      assert_equal 2.0.day,  24 * 3600 * 2
      assert_equal 3.0.days, 24 * 3600 * 3
    end
    
    def test_number_should_act_like_a_hour_duration
      assert_equal 1.hour,  3600
      assert_equal 2.hour,  3600 * 2
      assert_equal 3.hours, 3600 * 3
      
      assert_equal 1.0.hour,  3600
      assert_equal 2.0.hour,  3600 * 2
      assert_equal 3.0.hours, 3600 * 3
    end

    def test_number_should_act_like_a_minute_duration
      assert_equal 1.minute,  60
      assert_equal 2.minute,  60 * 2
      assert_equal 3.minutes, 60 * 3
      
      assert_equal 1.0.minute,  60
      assert_equal 2.0.minute,  60 * 2
      assert_equal 3.0.minutes, 60 * 3      
    end
    
    def test_number_should_act_like_a_second_duration
      assert_equal 1.second,  1
      assert_equal 2.second,  2
      assert_equal 3.seconds, 3
      
      assert_equal 1.0.second,  1
      assert_equal 2.0.second,  2
      assert_equal 3.0.seconds, 3
    end
     
  end
end