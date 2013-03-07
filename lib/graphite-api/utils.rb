require 'forwardable'

module GraphiteAPI
  module Utils
    
    def self.included base
      base.extend ClassUtils
      base.extend Forwardable
      base.__send__ :include, LoggerUtils
    end

    module LoggerUtils
      [:info,:error,:warn,:debug].each do |m|
        define_method m do |*args,&block|
          Logger.send m, *args, &block
        end
      end
    end

    module ClassUtils      
      def private_reader *args
        attr_reader *args
        private     *args
      end
    end
    
    def normalize_time time, slice
      slice = 60 if slice.nil?
      ((time || Time.now).to_i / slice * slice).to_i
    end
    
    def nested_zero_hash
      Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = 0} }
    end
    
    module_function
 
    def expand_host host
      host,port = host.split(":")
      port = port.nil? ? default_options[:port] : port.to_i
      [host,port]
    end

    def default_options
      {
        :backends => [],
        :cleaner_interval => 43200,
        :port => 2003,
        :log_level => :info,
        :cache => nil,
        :host => "localhost",
        :prefix => [],
        :interval => 60,
        :slice => 60,
        :pid => "/tmp/graphite-middleware.pid"
      }
    end

  end
end