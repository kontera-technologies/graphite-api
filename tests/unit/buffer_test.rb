require_relative "../minitest_helper"

module GraphiteAPI
  class BufferTester < MiniTest::Unit::TestCase

    def test_initialize    
      assert_raises(ArgumentError) { Buffer.new }

      options = {:shuki => :tuki}
      
      buffer(options).tap do |buffer_obj|
        assert_equal options,  buffer_obj.instance_variable_get(:@options)
        assert_equal Hash.new, buffer_obj.instance_variable_get(:@keys_to_send)
        assert_equal Hash.new, buffer_obj.instance_variable_get(:@streamer_buff)
        assert_equal false,    buffer_obj.instance_variable_get(:@reanimation_mode)
      end
      
      assert_equal(true,buffer(:reanimation_exp => 1).instance_variable_get(:@reanimation_mode))
    end
    
    def test_push
      today = Time.now
      tommorow = Time.now + 24 * 60 * 60
      options = Utils.default_options
      Utils.stubs(:normalize_time).with(today, 60).returns(today)
      Utils.stubs(:normalize_time).with(tommorow, 60).returns(tommorow)
      
      buffer.tap do |buffer_obj|
        metric  = {:shuki => 10, :blabla => 80}
        message = {:time => today, :metric => metric}
        buffer_obj << message
        assert_equal({today => metric},buffer_obj.instance_variable_get(:@buffer_cache))
        assert_equal({today => [:shuki,:blabla]},buffer_obj.instance_variable_get(:@keys_to_send))
      end
            
      buffer.tap do |buffer_obj|
        buffer_obj << {:metric => {'a' => 10},:time => today}
        buffer_obj << {:metric => {'a' => 10},:time => today}
        buffer_obj << {:metric => {'a' => 10},:time => today}
        buffer_obj << {:metric => {'a' => 10},:time => today}
        buffer_obj << {:metric => {'a' => 10},:time => today}
        buffer_obj << {:metric => {'a' => 10},:time => today}
        assert_equal({today=>{"a"=>60.0}},buffer_obj.instance_variable_get(:@buffer_cache))
        assert_equal({today => ['a']},buffer_obj.instance_variable_get(:@keys_to_send))
      end

      buffer.tap do |buffer_obj|
        buffer_obj << {:metric => {'a' => 10.2},:time => today}
        buffer_obj << {:metric => {'a' => 10.1},:time => today}
        buffer_obj << {:metric => {'a' => 10.2},:time => today}
        buffer_obj << {:metric => {'a' => 10.1},:time => today}
        buffer_obj << {:metric => {'a' => 10.1},:time => today}
        buffer_obj << {:metric => {'a' => 10.4},:time => today}
        assert_equal({today=>{"a"=>61.1}},buffer_obj.instance_variable_get(:@buffer_cache))
        assert_equal({today => ['a']},buffer_obj.instance_variable_get(:@keys_to_send))
      end
      
      buffer.tap do |buffer_obj|
        buffer_obj << {:metric => {'a' => 10.2},:time => today}
        buffer_obj << {:metric => {'b' => 10.1},:time => today}
        buffer_obj << {:metric => {'a' => 10.2},:time => today}
        buffer_obj << {:metric => {'b' => 10.1},:time => today}
        buffer_obj << {:metric => {'a' => 10.1},:time => today}
        buffer_obj << {:metric => {'b' => 10.4},:time => today}
        assert_equal({today=>{"a"=>30.5, "b"=>30.6}},buffer_obj.instance_variable_get(:@buffer_cache))
      end
      
      buffer.tap do |buffer_obj|
        buffer_obj << {:metric => {'a' => 10.2},:time => today}
        buffer_obj << {:metric => {'b' => 10.1},:time => tommorow}
        buffer_obj << {:metric => {'a' => 10.2},:time => tommorow}
        buffer_obj << {:metric => {'b' => 10.1},:time => today}
        buffer_obj << {:metric => {'a' => 10.1},:time => today}
        buffer_obj << {:metric => {'b' => 10.4},:time => tommorow}
        assert_equal({today=>{"a"=>20.3, "b"=>10.1}, tommorow=>{"b"=>20.5, "a"=>10.2}},buffer_obj.instance_variable_get(:@buffer_cache))
      end
      
    end
    
    
    def test_stream
      now = 1334850240
      
      buffer.tap do |buff|
        buff.stream "test.shuki.tuki 123 #{now}"
        buff.stream "\n"
        buff.stream "mem.usage 1"
        buff.stream "90 1326842563\n"
        buff.stream "test.shuki.tuki 123 #{now}\n"
        buff.stream "lo.tov \n"
        buff.stream "lo.tov 112332\n"
        buff.stream "lo."
        buff.stream "tov"
        buff.stream "\n"
        buff.stream "ken.tov 11.2332 231231321\n"
        buff.stream("client1",:client1)
        buff.stream("client2",:client2)
        buff.stream(" 1",:client1)
        buff.stream(" 2",:client2)
        buff.stream(" 213232\n",:client1)
        buff.stream(" 213232\n",:client2)
        buff.stream("a.b 1211 121212\nc.d 1211 121212\n",:client2)
        buff.stream("test.x 10 1334771088\ntest.z 10 1334771088\n",:client2)

        expected_buffer = { 
          1334850240 => {"test.shuki.tuki"=>246.0},
          1326842520 => {"mem.usage"=>190.0},
          231231300  => {"ken.tov"=>11.23},
          213180     => {"client1"=>1.0, "client2"=>2.0},
          121200     => {"a.b"=>1211.0, "c.d"=>1211.0},
          1334771040 => {"test.x"=>10.0, "test.z"=>10.0}
        }.sort
        
        expected_keys = {
          1334850240 => ["test.shuki.tuki"],
          1326842520 => ["mem.usage"],
          231231300  => ["ken.tov"],
          213180     => ["client1", "client2"],
          121200     => ["a.b", "c.d"],
          1334771040 => ["test.x", "test.z"]
        }.sort
        
        assert_equal(expected_buffer,buff.instance_variable_get(:@buffer_cache).sort)
        assert_equal(expected_keys,buff.instance_variable_get(:@keys_to_send).sort)
        
        buff.instance_variable_get(:@streamer_buff).tap do |streamer|
          assert !streamer.has_key?(nil)
          assert !streamer.has_key?(:client1)
          assert !streamer.has_key?(:client2)
        end
        
      end
    end

    def test_pull
      buffer.tap do |buff|
        input = { 
          1334850240 => {"test.shuki.tuki"=>246.0},
          1326842520 => {"mem.usage"=>190.0},
          231231300  => {"ken.tov"=>11.23},
          213180     => {"client1"=>1.0, "client2"=>2.0},
          121200     => {"a.b"=>1211.0, "c.d"=>1211.0},
          1334771040 => {"test.x"=>10.0, "test.z"=>10.0}
        }
        
        keys = {
          1334850240 => ["test.shuki.tuki"],
          1326842520 => ["mem.usage"],
          231231300  => ["ken.tov"],
          213180     => ["client1", "client2"],
          121200     => ["a.b", "c.d"],
          1334771040 => ["test.x", "test.z"]
        }
        
        buff.instance_variable_set(:@buffer_cache,input.clone)
        assert_equal([],buff.pull)
        
        buff.instance_variable_set(:@buffer_cache,input.clone)
        buff.instance_variable_set(:@keys_to_send,keys.clone)

        buff.pull.sort.tap do |array|
          assert_equal(["a.b", 1211.0, 121200],array[0])
          assert_equal(["c.d", 1211.0, 121200],array[1])
          assert_equal(["client1", 1.0, 213180],array[2])
          assert_equal(["client2", 2.0, 213180],array[3])
          assert_equal(["ken.tov", 11.23, 231231300],array[4])
          assert_equal(["mem.usage", 190.0, 1326842520],array[5])
          assert_equal(["test.shuki.tuki", 246.0, 1334850240],array[6])
          assert_equal(["test.x", 10.0, 1334771040],array[7])
          assert_equal(["test.z", 10.0, 1334771040],array[8])
          assert_equal(9,array.size)
        end
    
        buff.instance_variable_set(:@buffer_cache,input.clone)
        buff.instance_variable_set(:@keys_to_send,keys.clone)
        
        buff.pull(:string).sort.tap do |array|
          assert_equal("a.b 1211.0 121200",array[0])
          assert_equal("c.d 1211.0 121200",array[1])
          assert_equal("client1 1.0 213180",array[2])
          assert_equal("client2 2.0 213180",array[3])
          assert_equal("ken.tov 11.23 231231300",array[4])
          assert_equal("mem.usage 190.0 1326842520",array[5])
          assert_equal("test.shuki.tuki 246.0 1334850240",array[6])
          assert_equal("test.x 10.0 1334771040",array[7])
          assert_equal("test.z 10.0 1334771040",array[8])
          assert_equal(9,array.size)
        end
      end
    end

    private
    
    def buffer options = Utils.default_options
      Buffer.new options
    end
    
  end
end