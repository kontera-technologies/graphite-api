require_relative "../minitest_helper"

module GraphiteAPI
  class ClientTester < Unit::TestCase
    
    def test_nicer_method_to_get_client
      assert_kind_of ::GraphiteAPI::Client, ::GraphiteAPI.new({:graphite => 'shuki'})
    end

    def test_initialize
      assert_raises(ArgumentError) { Client.new }
      assert_raises(ArgumentError) { Client.new("a" => 1) }
      
      opt = {:shuki => :tuki, :interval => 22}
      
      Client::any_instance.expects(:validate).with(opt).returns(opt)
      Client::any_instance.expects(:build_options).with(opt).returns(opt)
      
      # Should initialize these two also
      GraphiteAPI::Buffer.expects(:new).with(opt).returns(:buffer)
      GraphiteAPI::Connector::Group.expects(:new).with(opt).returns(:connector_group)

      Zscheduler.expects(:every)
      Client.new(opt).tap do |client|
        assert_equal opt, client.instance_variable_get(:@options)
        assert_equal :buffer, client.instance_variable_get(:@buffer)
        assert_equal :connector_group, client.instance_variable_get(:@connectors)
      end
      
    end

    def test_metrics
       get_client.tap do |my_client|
         my_metrics = {"a" => 1232,:b => 232, "c" => "123ksadkhjdas"}
         my_time = Time.now
         my_buffer = Object.new
         my_client.expects(:buffer).returns(my_buffer)
         my_buffer.expects(:push).with(:metric => my_metrics, :time => my_time)
         my_client.metrics(my_metrics, my_time)
       end
    end
    
    def test_join
      get_client.tap do |my_client|
        my_buffer = Object.new
        my_buffer.expects(:new_records?).returns(false)
        my_client.expects(:buffer).returns(my_buffer)
        my_client.expects(:sleep).never
        my_client.join
      end
    end
    
    def test_stop
      Zscheduler.expects :stop
      get_client.stop
    end
    
    def test_every
      client = get_client
      block = proc {'zubi'}
      frequency = 21
      Zscheduler::expects(:every).with(frequency,&block)
      client.every(frequency,&block)
    end
    
    def test_client_should_be_thread_safe
      client = get_client
      time1 = Time.at(1234567) # 1234560
      time2 = Time.at(12345678) # 12345660      
      
      (1..10).map do
        Thread.new do
          1.upto(1000) do
            client.metrics({"shuki1" => 1, "shuki2" => 1},time1)
            client.metrics({"shuki3" => 1, "shuki4" => 1},time2)
          end
        end
      end.map(&:join)
      
      expected = [
        ["shuki1", 10000.0, 1234560],
        ["shuki2", 10000.0, 1234560],
        ["shuki3", 10000.0, 12345660],
        ["shuki4", 10000.0, 12345660]
      ]
      
      assert_equal expected, client.__send__(:buffer).pull
    end
    
    def test_increment
      get_client.tap do |client|
        client.expects(:metrics).with({"key1" => 999, "key2" => 999},Time.at(1010))
        client.increment("key1","key2", {:by => 999, :time => Time.at(1010)})
        
        client.expects(:metrics).with({"key1" => 1, "key2" => 1},Time.at(123456))
        client.increment("key1","key2", {:time => Time.at(123456)})
      end
    end

    def test_direct_send
      get_client.tap do |client|
        client.instance_variable_get(:@options)[:direct] = true
        client.expects(:send_metrics)
        client.metrics("blabla" => 1)
      end
    end

    private

    def get_client(options = Utils::default_options) 
      Zscheduler.expects(:every)
      Client.new(options.merge(:graphite => "localhost", :interval => 60))
    end

  end
end
