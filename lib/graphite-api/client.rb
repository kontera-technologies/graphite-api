module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector
    
    def initialize(host,opt = {})
      @buffer = []
      @options = {
        :host => host,
        :port => 2003,
        :prefix => [],
        :interval => 60,
        :aggregate => true
      }.merge opt
      @options[:prefix] = [@options[:prefix]] unless @options[:prefix].kind_of?(Array)
      @connector = Connector.new(*options.values_at(:host,:port))
      Scheduler.every(options[:interval]) { send_metrics }
    end

    def add_metrics(m)
      buffer << m
    end
    
    def join
      Scheduler.join
    end
    
    def every(frequency,&block)
      Scheduler.every(frequency,&block)
    end
    
    def stop
      Scheduler.stop
    end
    
    protected
    def send_metrics
      time = Time.now.to_i
      records = []
      agg_hash = Hash.new {|h,k| h[k] = 0}
      while (record = buffer.shift)
        if options[:aggregate]
          record.each {|k,v| agg_hash[k] += v.to_f}
        else
          records << record
        end
      end
      records = [agg_hash] if options[:aggregate]
      records.each do |hash|
        hash.each do |key,val|
          connector.puts "#{prefix_str(options[:prefix])}#{key} #{val.to_f} #{time}"
        end
      end
    end
    
    def prefix_str(prefix)
      "#{prefix.join('.')}#{'.' if !prefix.empty?}"
    end
    
  end
end