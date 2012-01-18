# -----------------------------------------------------
# Graphite Client
# Send metrics to graphite (or to some kind of middleware/proxy) 
# -----------------------------------------------------
# Usage
#   client = GraphiteAPI::Client.new(
#    :host => "127.0.0.1",                       # Graphite sever (can even be pointed to GraphiteAPI middleware instance)
#    :port => 2003,                              # Graphite (or GraphiteAPI middleware) server port, default 2003
#    :prefix => ["kontera","prefix","test"],     # Prefix, will add kontera.prefix.test to each key
#    :interval => 60,                            # Send to Graphite every X seconds, default is 60
#  )
#
#  client.add_metrics("shuki.tuki" => 10.7)      # will send kontera.prefix.test.shuki.tuki 10.7 11212312321
#  client.add_metrics("shuki.tuki" => 10.7,"moshe.shlomo" => 22.9)
#  client.add_metrics({"shuki.tuki" => 10.7,"moshe.shlomo" => 22.9},Time.at(11212312321)) # with timestamp 
# 
#  # every X seconds
#  client.every(1) do 
#    client.add_metrics("one_seconds#{rand 10}" => 10) # kontera.prefix.test.one_seconds 20.2 12321231312
#  end
#
#  client.every(5) do
#    client.add_metrics("five_seconds" => 10) # kontera.prefix.test.five_seconds 20.2 12321231312
#  end
#
#
# client.join # wait until all metrics reported
# -----------------------------------------------------
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