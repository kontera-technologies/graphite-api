# -----------------------------------------------------
# Graphite Client
# Send metrics to graphite (or to some kind of middleware/proxy) 
# -----------------------------------------------------
# Usage
#
#  client = GraphiteAPI::Client.new(
#    :graphite => "graphite.example.com:2003",
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
    include Utils
    
    attr_reader :options,:buffer,:connectors
    
    def initialize opt
      @options    = build_options(validate(opt.clone))
      @buffer     = GraphiteAPI::Buffer.new(options)
      @connectors = GraphiteAPI::ConnectorGroup.new(options)
      start_scheduler
    end

    def add_metrics(m,time = Time.now)
      buffer.push(:metric => m, :time => time)
    end

    def join
      sleep 0.1 while buffer.new_records?
    end
    
    def stop
      Scheduler.stop
    end
    
    def every(frequency,&block)
      Scheduler.every(frequency,&block)
    end

    protected
    
    def start_scheduler
      Scheduler.every(options[:interval]) { send_metrics }
    end
    
    def send_metrics
      EventMachine::defer(proc { buffer.pull(:string) }, proc { |r| connectors.publish(r) })
    end
    
    def validate opt
      raise ArgumentError.new ":graphite must be specified" if opt[:graphite].nil?
      opt
    end
    
    def build_options opt
      default_options.tap do |options_hash|
        options_hash[:backends] << expand_host(opt.delete(:graphite))
        options_hash.merge! opt
        options_hash.freeze
      end
    end
    
  end
end