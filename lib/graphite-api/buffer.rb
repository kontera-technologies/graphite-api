# -----------------------------------------------------
# Buffer Object
# Handle Socket & Client data streams
# -----------------------------------------------------
# Usage:
#     buff = GraphiteAPI::Buffer.new(GraphiteAPI::Utils.default_options)
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
    include Utils
    
    CHARS_TO_BE_IGNORED = ["\r"]
    END_OF_STREAM = "\n"
    VALID_MESSAGE = /^[\w|\.|-]+ \d+(?:\.|\d)* \d+$/
    
    def initialize options
      @options = options
      @queue = Queue.new
      @streamer = Hash.new {|h,k| h[k] = ""}
      @cache = Cache::Memory.new options if options[:cache]
    end
    
    private_reader :queue, :options, :streamer, :cache
    
    # this method isn't thread safe
    # use #push for multiple threads support
    def stream message, client_id = nil
      message.gsub(/\t/,' ').each_char do |char|
        next if invalid_char? char
        streamer[client_id] += char 
        
        if closed_stream? streamer[client_id]
          if valid_stream_message? streamer[client_id]
            push stream_message_to_obj streamer[client_id]
          end
          streamer.delete client_id
        end
      end
    end
    
    # Add records to buffer
    # push({:metric => {'a' => 10},:time => Time.now})
    def push obj
      debug [:buffer,:add, obj]
      queue.push obj
      nil
    end

    alias_method :<<, :push

    def pull format = nil
      data = nested_zero_hash

      counter = 0
      while new_records?
        break if ( counter += 1 ) > 1_000_000 # TODO: fix this
        hash = queue.pop
        time = normalize_time(hash[:time],options[:slice])
        hash[:metric].each { |k,v| data[time][k] += v.to_f }
      end
      
      data.map do |time, hash|
        hash.map do |key, value|
          value = cache.incr(time,key,value) if cache
          results = ["#{prefix}#{key}",("%f"%value).to_f, time]
          format == :string ? results.join(" ") : results
        end
      end.flatten(1)
    end
    
    def new_records?
      !queue.empty?
    end
    
    def inspect
      "#<GraphiteAPI::Buffer:%s @quque#size=%s @streamer=%s>" % 
        [ object_id, queue.size, streamer]
    end
    
    private
    
    def stream_message_to_obj message
      parts = message.split
      {:metric => { parts[0] => parts[1] },:time => Time.at(parts[2].to_i) }
    end
    
    def invalid_char? char
      CHARS_TO_BE_IGNORED.include? char
    end
    
    def closed_stream? string
      string[-1,1] == END_OF_STREAM
    end
    
    def valid_stream_message? message
      message =~ VALID_MESSAGE
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
