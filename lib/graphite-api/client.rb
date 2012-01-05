module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector

    def initialize(host,opt = {})
      @options = Utils.default_options.merge opt
      @options[:host] = host
      @options[:prefix] = ([@options[:prefix]].flatten.join('.')) << '.' if !@options[:prefix].empty?
      @buffer  = GraphiteAPI::Buffer.new(options)
      @connector = GraphiteAPI::Connector.new(*options.values_at(:host,:port))
      GraphiteAPI::Scheduler.every(options[:interval]) {send_metrics}
    end

    def add_metrics(m,time = Time.now)
      buffer << {:metric => m, :time => time}
    end

    def join
      Scheduler.join
    end

    def stop
      Scheduler.stop
    end
    
    def every(frequency,&block)
      Scheduler.every(frequency,&block)
    end

    protected
    def send_metrics
      buffer.each {|arr| connector.puts arr.join(" ")} 
    end
    
    def prefix
      @options[:prefix]
    end
    
  end
end