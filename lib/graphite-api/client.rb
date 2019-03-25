require 'forwardable'
require 'thread'
require 'timers'

module GraphiteAPI
  class Client
    extend Forwardable

    def_delegator :timers, :cancel
    def_delegator :timers, :pause
    def_delegator :timers, :resume

    def_delegator :buffer, :stream

    attr_reader :options, :buffer, :connectors, :mu
    private     :options, :buffer, :connectors, :mu

    def initialize opt
      @options = build_options validate opt.clone
      @buffer  = GraphiteAPI::Buffer.new options, timers
      @connectors = GraphiteAPI::Connector::Group.new options
      @mu = Mutex.new

      timers.every(options[:interval], true, &method(:send_metrics!)) unless options[:direct]
    end

    def timers
      @timers ||= Timers::Group.new.tap {|t| Thread.new { loop { t.wait } } }
    end

    # throw exception on Socket error
    def check!
      connectors.check!
    end

    def every interval, &block
      @timers.every(interval) { block.arity == 1 ? block.call(self) : block.call }
    end

    def metrics metric, time = nil, aggregation_method = nil
      return if metric.empty?
      buffer.push :metric => metric, :time => (time || Time.now), :aggregation_method => aggregation_method
      send_metrics! if options[:direct]
    end

    def increment(*keys)
      opt = {}
      opt.merge! keys.pop if keys.last.is_a? Hash
      by = opt.fetch(:by,1)
      time = opt.fetch(:time,Time.now)
      metric = keys.inject({}) {|h,k| h.merge k => by }
      metrics(metric, time)
    end

    def join
      sleep while buffer.new_records?
    end

    def self.default_options
      {
        :backends => [],
        :cleaner_interval => 43200,
        :port => 2003,
        :log_level => :info,
        :cache => nil,
        :host => "localhost",
        :prefix => [],
        :interval => 0,
        :slice => 60,
        :pid => "/tmp/graphite-middleware.pid",
        :default_aggregation_method => :sum
      }
    end

    protected

    def validate options
      options.tap do |opt|
        raise ArgumentError.new ":graphite must be specified" if opt[:graphite].nil?
      end
    end

    def build_options opt
      self.class.default_options.tap do |options_hash|
        options_hash[:backends] = Array(opt.delete :graphite)
        options_hash.merge! opt
        options_hash[:direct] = options_hash[:interval] == 0
        options_hash[:slice] = 1 if options_hash[:direct]
      end
    end

    def send_metrics! *_
      mu.synchronize { connectors.publish buffer.pull :string if buffer.new_records? }
    end

  end
end
