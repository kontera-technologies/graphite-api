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
      GraphiteAPI::Buffer.expects(:new).with(opt).returns(:buffer)
      GraphiteAPI::ConnectorGroup.expects(:new).with(opt).returns(:connector_group)
      
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
    
    private
    
    def get_client(options = Utils::default_options) 
      Client.new(options.merge(:graphite => "localhost"))
    end
    
  end
end