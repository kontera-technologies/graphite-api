require_relative "../minitest_helper"

module GraphiteAPI
  class ClientTester < Unit::TestCase

    def test_initialize
      assert_raises(ArgumentError) { Client.new }
      assert_raises(ArgumentError) { Client.new("a" => 1) }
      
      opt = {:shuki => :tuki, :interval => 22}
      
      Client::any_instance.expects(:validate).with(opt).returns(opt)
      Client::any_instance.expects(:build_options).with(opt).returns(opt)
      
      # Should initialize these two also
      GraphiteAPI::SafeBuffer.expects(:new).with(opt).returns(:buffer)
      GraphiteAPI::ConnectorGroup.expects(:new).with(opt).returns(:connector_group)

      Reactor.expects(:every)
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
      Reactor.expects :stop
      get_client.stop
    end
    
    def test_every
      client = get_client
      block = proc {'zubi'}
      frequency = 21
      Reactor::expects(:every).with(frequency,&block)
      client.every(frequency,&block)
    end
    
    def test_fancy_metrics
      get_client.tap do |client|
        client.expects(:metrics).with("a.b.c.d.e.f.g" => 9)
        client.a.b.c.d.e.f.g 9
        
        client.expects(:metrics).with({"a.b.c.d.e.f.g" => 9}, Time.at(11111))
        client.a.b.c.d.e.f.g(9, Time.at(11111))
      end
    end

    def test_client_should_be_thread_safe
      now = Time.now
      
      client = get_client#(:cache => 1000000)
      time1 = Time.at(1234567) # 1234560
      time2 = Time.at(12345678) # 12345660      
      
      (1..50).map do
        Thread.new do
          1.upto(1000) do
            client.shuki1(1,time1)
            client.shuki2(1,time1)
            client.shuki3(1,time2)
            client.shuki4(1,time2)
          end
        end
      end.map(&:join)
      
      expected = [
        ["shuki1", 50000.0, 1234560],
        ["shuki2", 50000.0, 1234560],
        ["shuki3", 50000.0, 12345660],
        ["shuki4", 50000.0, 12345660]
      ]
      
      assert_equal expected, client.__send__(:buffer).pull
      #p(Time.now.to_i - now.to_i)
    end

    private

    def get_client(options = Utils::default_options) 
      Reactor.expects(:every)
      Client.new(options.merge(:graphite => "localhost"))
    end

  end
end