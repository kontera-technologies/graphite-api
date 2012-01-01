module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector

    def initialize(host,opt = {})
      @options = {:host => host,:port => 2003,:prefix => [],:interval => 300}.merge opt
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
      buffer.each do |time,metrics|
        metrics.map {|k,v| "#{prefix}#{k} #{v} #{time}"}.map {|o| connector.puts o}
      end
    end
    
    def prefix
      @options[:prefix]
    end
    
  end
end