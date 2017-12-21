require File.expand_path '../utils', __FILE__

module GraphiteAPI
  class Client
    include Utils

    private_reader :options, :buffer, :connectors

    def initialize opt
      @options = build_options validate opt.clone
      @buffer  = GraphiteAPI::Buffer.new options
      @connectors = GraphiteAPI::Connector::Group.new options
      
      Zscheduler.every(options[:interval]) { send_metrics } unless options[:direct]
    end

    def_delegator Zscheduler, :loop, :join
    def_delegator Zscheduler, :stop

    def every interval, &block
      Zscheduler.every( interval ) { block.arity == 1 ? block.call(self) : block.call }
    end

    def metrics metric, time = Time.now 
      return if metric.empty?
      buffer.push :metric => metric, :time => time
      send_metrics if options[:direct]
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

    protected

    def validate options
      options.tap do |opt|
        raise ArgumentError.new ":graphite must be specified" if opt[:graphite].nil?
      end
    end

    def build_options opt
      default_options.tap do |options_hash|
        options_hash[:backends].push expand_host opt.delete :graphite
        options_hash.merge! opt
        options_hash[:direct] = options_hash[:interval] == 0
        options_hash[:slice] = 1 if options_hash[:direct]
      end
    end

    def send_metrics
      connectors.publish buffer.pull :string if buffer.new_records?
    rescue Exception => e
      Zscheduler.init_reactor? ? raise : Logger.error("Publish Error: #{e}\n#{e.backtrace.join("\n")}")
    end

  end
end
