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
#  client.webServer.web01.loadAvg 10.7 
#  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.to_i

#  client.metrics "webServer.web01.loadAvg" => 10.7
#  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.to_i
#  
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

    private_reader :options, :buffer, :connectors, :direct_send

    def initialize opt
      @options = build_options validate opt.clone
      @buffer  = GraphiteAPI::Buffer.new options
      @connectors = GraphiteAPI::Connector::Group.new options
      @direct_send = @options[:interval] == 0

      if direct_send
        options[:slice] = 1
      else
        every(options.fetch(:interval),&method(:send_metrics))
      end

    end

    def_delegator Zscheduler, :loop, :join
    def_delegator Zscheduler, :stop

    def every interval, &block
      Zscheduler.every( interval ) { block.arity == 1 ? block.call(self) : block.call }
    end

    def metrics metric, time = Time.now 
      buffer.push :metric => metric, :time => time
      send_metrics if direct_send
    end

    alias_method :add_metrics, :metrics

    # increment keys
    #
    # increment("key1","key2")
    # => metrics("key1" => 1, "key2" => 1)
    # 
    # increment("key1","key2", {:by => 999})
    # => metrics("key1" => 999, "key2" => 999)
    #
    # increment("key1","key2", {:time => Time.at(123456)})
    # => metrics({"key1" => 1, "key2" => 1},Time.at(123456))
    def increment(*keys)
      opt = {}
      opt.merge! keys.pop if keys.last.is_a? Hash
      by = opt.fetch(:by,1)
      time = opt.fetch(:time,Time.now)
      metric = keys.inject({}) {|h,k| h.tap { h[k] = by}}
      metrics(metric, time)
    end

    def join
      sleep while buffer.new_records?
    end

    def method_missing m, *args, &block
      Proxy.new( self ).send(m,*args,&block)
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
      end
    end

    def send_metrics
      connectors.publish buffer.pull :string if buffer.new_records?
    end

  end
end
