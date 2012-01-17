module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector

    def initialize(opt)
      @options   = GraphiteAPI::Utils.default_options.merge opt
      @buffer    = GraphiteAPI::Buffer.new(options)
      @connector = GraphiteAPI::Connector.new(*options.values_at(:host,:port))
      start_scheduler
    end

    def add_metrics(m,time = Time.now)
      buffer << {:metric => m, :time => time}
    end

    def join
      sleep 1 while buffer.got_new_records?
    end
    
    def stop
      Scheduler.stop
    end
    
    def every(frequency,&block)
      Scheduler.every(frequency,&block)
    end

    protected
    def start_scheduler
      Scheduler.every(options[:interval]) {send_metrics}
    end
    
    def send_metrics
      buffer.each {|arr| connector.puts arr.join(" ")} 
    end 
    
  end
end