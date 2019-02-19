# -----------------------------------------------------
# Buffer Object
# Handle Socket & Client data streams
# -----------------------------------------------------
# Usage:
#     buff = GraphiteAPI::Buffer.new(GraphiteAPI::Client.default_options)
#     buff << {:metric => {"load_avg" => 10},:time => Time.now}
#     buff << {:metric => {"load_avg" => 30},:time => Time.now}
#     buff.stream "mem.usage 1"
#     buff.stream "90 1326842563\n"
#     buff.stream "shuki.tuki 999 1326842563\n"
#     buff.pull.each {|o| p o}
#
# Produce:
#    ["load_avg", 40.0, 1326881160]
#    ["mem.usage", 190.0, 1326842520]
#    ["shuki.tuki", 999.0, 1326842520]
# -----------------------------------------------------
require 'thread'
require 'set'

module GraphiteAPI
  class Buffer

    IGNORE = ["\r"]
    END_OF_STREAM = "\n"
    VALID_MESSAGE = /^[\w|\.|-]+ \d+(?:\.|\d)* \d+$/

    AGGREGATORS = {
      sum: ->(old_v, new_v) { (old_v || 0) + new_v },
      avg: ->(old_v, new_v) {
        sum, size = old_v || [0.0, 0]
        [sum + new_v, size + 1]
      },
      replace: ->(old_v, new_v) { new_v },
    }
    FINALIZERS = {
      avg: ->((sum, size)) { sum / size },
    }

    def initialize options
      @options = options
      @queue = Queue.new
      @streamer = Hash.new {|h,k| h[k] = ""}
      @cache = Cache::Memory.new(options) if options[:cache]
    end

    attr_reader :queue, :options, :streamer, :cache

    # this method isn't thread safe
    # use #push for multiple threads support
    def stream message, client_id = nil
      message.gsub(/\t/,' ').each_char do |char|
        next if invalid_char? char
        streamer[client_id] += char

        if closed_stream? streamer[client_id]
          if streamer[client_id] =~ VALID_MESSAGE
            push stream_message_to_obj streamer[client_id]
          end
          streamer.delete client_id
        end
      end
    end

    # Add records to buffer
    # push({:metric => {'a' => 10},:time => Time.now,:aggregation_method => :sum})
    def push obj
      Logger.debug [:buffer,:add, obj]
      queue.push obj
      nil
    end

    alias_method :<<, :push

    def pull format = nil
      data = Hash.new { |h,time| h[time] = Hash.new { |h2,metric| h2[metric] = cache ? cache.get(time, metric) : nil } }
      aggregation_methods = Hash.new { |h, time| h[time] = options[:aggregation_method] }

      counter = 0
      while new_records? and (counter += 1) < 1_000_000
        metrics, time, method = queue.pop.values_at(:metric, :time, :aggregation_method)

        normalized_time = normalize_time(time, options[:slice])
        metrics.each do |metric, value|
          aggregation_methods[metric] = method if method
          data[normalized_time][metric] = AGGREGATORS[aggregation_methods[metric]].call(data[normalized_time][metric], value.to_f)
          cache.set(normalized_time, metric, data[normalized_time][metric]) if cache
        end
      end

      data.map do |time, metrics|
        metrics.map do |metric, raw_value|
          value = (FINALIZERS[aggregation_methods[metric]] || ->(x) {x}).call(raw_value)
          results = ["#{prefix}#{metric}",("%f"%value).to_f, time]
          format == :string ? results.join(" ") : results
        end
      end.flatten(1)
    end

    def inspect
      "#<GraphiteAPI::Buffer:%s @quque#size=%s @streamer=%s>" %
        [ object_id, queue.size, streamer]
    end

    def new_records?
      !queue.empty?
    end

    private

    def normalize_time time, slice
      slice = 60 if slice.nil?
      ((time || Time.now).to_i / slice * slice).to_i
    end

    def stream_message_to_obj message
      parts = message.split
      {:metric => { parts[0] => parts[1] },:time => Time.at(parts[2].to_i) }
    end

    def invalid_char? char
      IGNORE.include? char
    end

    def closed_stream? string
      string[-1,1] == END_OF_STREAM
    end

    def prefix
      @prefix ||= if options[:prefix] and !options[:prefix].empty?
        Array(options[:prefix]).join('.') << '.'
      else
        ""
      end
    end

  end
end
