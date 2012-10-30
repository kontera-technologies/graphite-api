require_relative "../minitest_helper"

module GraphiteAPI
  class RunnerTester < MiniTest::Unit::TestCase

    def test_initialize
      GraphiteAPI::CLI.expects(:parse).with([:shuki,:tuki],{a: :b})
      Runner.any_instance.expects(:options).returns({a: :b})
      Runner.any_instance.expects(:validate_options)
      Runner.new([:shuki,:tuki])
    end
    
    def test_run
      get_obj(daemonize: true, pid: 10).tap do |obj|
        obj.expects(:daemonize).with(10)
        obj.run
      end
      
      get_obj(daemonize: false).tap do |obj|
        obj.expects(:daemonize).never
        obj.expects(:run)
        obj.run
      end
    end
    
    def test_options
      get_obj(default_options(shuki: :tuki)).tap do |obj|
        assert_equal default_options(shuki: :tuki), obj.__send__(:options)
        Utils.expects(:default_options).returns(:zevel)
        obj.instance_variable_set(:@options,nil)
        assert_equal obj.__send__(:options), :zevel
      end        
    end
    
    def test_run!
      options = default_options(log_file: 'log', log_level: :debug)
      Logger.expects(:init).with(std: 'log', level: :debug)
      Middleware.expects(:start).with(options)
      get_obj(options).__send__(:run!)
    end
    
    def test_validate_options
      m = Runner.instance_method(:validate_options)
      get_obj(:backends => []).tap do |obj|
        obj.expects(:abort).with("You must specify at least one graphite host")
        m.bind(obj).call
        obj.__send__(:validate_options)
        obj.__send__(:options)[:backends] = [1]
        obj.__send__(:validate_options)
      end
    end
    
    def test_daemonize_method_exist
      assert get_obj.respond_to? :daemonize, true
    end
    
    private
    
    def get_obj options = {}
      Runner.any_instance.stubs(:validate_options)
      Runner.new([]).tap {|o| o.instance_variable_set(:@options,default_options(options))}
    end
    
    def default_options hash
      Utils.default_options.merge(hash)
    end
    
  end
end