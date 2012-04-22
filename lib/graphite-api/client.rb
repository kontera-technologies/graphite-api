# -----------------------------------------------------
# Graphite Client
# Send metrics to graphite (or to some kind of middleware/proxy) 
# -----------------------------------------------------
# Usage
#
#  client = GraphiteAPI::Client.new(
#    :host => "graphite.example.com",
#    :port => 2003,
#    :prefix => ["example","prefix"], # add example.prefix to each key
#    :interval => 60                  # send to graphite every 60 seconds
#    )
#  
#  # Simple:
#  client.add_metrics("webServer.web01.loadAvg" => 10.7)
#  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.stamp
#  
#  # Multiple with time:
#  client.add_metrics({
#	  "webServer.web01.loadAvg" => 10.7,
#	  "webServer.web01.memUsage" => 40
#  },Time.at(1326067060))
#  # => example.prefix.webServer.web01.loadAvg  10.7 1326067060
#  # => example.prefix.webServer.web01.memUsage 40 1326067060
#  
#  # Every 10 sec
#  client.every(10) do
#    client.add_metrics("webServer.web01.uptime" => `uptime`.split.first.to_i) 
#  end
#  
#  client.join # wait...
# -----------------------------------------------------
module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector
    
    def initialize(opt)
      @options   = GraphiteAPI::Utils.default_options.merge opt
      @buffer    = GraphiteAPI::Buffer.new(options)
      @connector = GraphiteAPI::Connector.new(*options.values_at(:host,:port))
      @connectors = GraphiteAPI::ConnectorGroup.new(options)
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
      connectors.publish buffer.pull(:string)
    
  end
end