require 'thread'
require 'set'

module GraphiteAPI
  class SafeBuffer
    include Utils
    
    def initialize options
      @options = options
      @queue = Queue.new
      @streamer = Hash.new {|h,k| h[k] = ""}

      if options[:reanimation_exp]
        @cache = Cache::Memory.new options[:reanimation_exp]
      end      
    end
    
    private_reader :queue, :options, :streamer, :cache
    
    # {:metric => {'a' => 10},:time => today}
    def push hash
      debug [:buffer,:add, hash]
      time = Utils.normalize_time(hash[:time],options[:slice])
      hash[:metric].each { |k,v| queue.push [time,k,v] }
    end
    
    alias_method :<<, :push

    # this method isn't thread safe
    # if you are running with multiple threads
    # use #push instead
    def stream message, client_id = nil
      message.gsub(/\t/,' ').each_char do |char|
        next if invalid_char? char
        streamer[client_id] += char 
        
        if closed_stream? streamer[client_id]
          if valid_stream_message streamer[client_id]
            push stream_message_to_obj streamer[client_id]
          end
          streamer.delete client_id
        end
      end
    end
    
    def pull format = nil
      data = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0} }
      while new_records?
        time, key, value = queue.pop
        data[time][key] += value.to_f
      end
      data.map do |time, hash|
        hash.map do |key, value|
          value = cache.incr(time,key,value) if cache
          results = ["#{prefix}#{key}",("%.2f"%value).to_f, time]
          format == :string ? results.join(" ") : results
        end
      end.flatten(1)
    end
    
    def new_records?
      !queue.empty?
    end
    
    private
    
    def stream_message_to_obj message
      parts = message.split
      {:metric => { parts[0] => parts[1] },:time => Time.at(parts[2].to_i) }
    end
    
    def invalid_char? char
      ["\r"].include? char
    end
    
    def closed_stream? string
      string[-1,1] == "\n"
    end
    
    def valid_stream_message message
      message =~ /^[\w|\.]+ \d+(?:\.|\d)* \d+$/
    end
    
    def prefix
      @prefix ||= options[:prefix].empty? ? '' : Array(options[:prefix]).join('.') << '.'
    end
        
  end
end