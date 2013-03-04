# -----------------------------------------------------
# Graphite Client
# Send metrics to graphite (or to some kind of middleware/proxy) 
# -----------------------------------------------------
# Usage
#
#  client = GraphiteAPI::Client.new(  
#   :graphite => "graphite.example.com:2003",
#   :prefix   => ["example","prefix"], # add example.prefix to each key
#   :slice    => 60.seconds            # results are aggregated in 60 seconds slices
#   :interval => 60.seconds            # send to graphite every 60 seconds
#  )
#  
#  # Simple
#  client.webServer.web01.loadAvg 10.7 
#  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.to_i

#  # "Same Same But Different" ( http://en.wikipedia.org/wiki/Tinglish )
#  client.metrics "webServer.web01.loadAvg" => 10.7
#  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.to_i
#  
#  # Multiple with event time
#  client.metrics({
#   "webServer.web01.loadAvg"  => 10.7,
#   "webServer.web01.memUsage" => 40
#  },Time.at(1326067060))
#  # => example.prefix.webServer.web01.loadAvg  10.7 1326067060
#  # => example.prefix.webServer.web01.memUsage 40 1326067060
# 
#  #  Timers
# client.every 10.seconds do |c|
#   c.webServer.web01.uptime `uptime`.split.first.to_i
#   # => example.prefix.webServer.web01.uptime 40 1326067060
# end
# 
# client.every 52.minutes do |c|
#   c.abcd.efghi.jklmnop.qrst 12 
#   # => example.prefix.abcd.efghi.jklmnop.qrst 12 1326067060
# end
# 
# client.join # wait...
# -----------------------------------------------------

require File.expand_path '../utils', __FILE__

module GraphiteAPI
  class Client
    include Utils

    def initialize opt
      @options = build_options validate opt.clone
      @buffer  = GraphiteAPI::SafeBuffer.new options
      @connectors = GraphiteAPI::ConnectorGroup.new options
      
      every options.fetch :interval do
        connectors.publish buffer.pull :string if buffer.new_records?
      end
      
    end

    private_reader :options, :buffer, :connectors

    def_delegator :"GraphiteAPI::Reactor", :loop
    def_delegator :"GraphiteAPI::Reactor", :stop
    
    def every interval, &block
      Reactor.every( interval ) { block.call self }
    end
    
    def metrics metric, time = Time.now 
      buffer.push :metric => metric, :time => time
    end

    def join
      sleep while buffer.new_records?
    end
    
    def method_missing m, *args, &block
      Proxy.new( self ).send m, *args, &block
    end
    
    protected
    
    class Proxy
      include Utils
      
      def initialize client
        @client = client
        @keys = []
      end
      
      private_reader :client, :keys
      
      def method_missing m, *args, &block
        keys.push m
        if keys.size > 10 # too deep
          super
        elsif args.any?
          client.metrics(Hash[keys.join("."),args.first],*args[1..-1])
        else
          self
        end
      end
      
    end
            
    def validate options
      options.tap do |opt|
        raise ArgumentError.new ":graphite must be specified" if opt[:graphite].nil?
      end
    end
    
    def build_options opt
      default_options.tap do |options_hash|
        options_hash[:backends].push expand_host opt.delete :graphite
        options_hash.merge! opt
        options_hash.freeze
      end
    end
    
  end
end