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
module GraphiteAPI
  class Buffer
    include Utils
    
    attr_reader :options,:keys_to_send,:reanimation_mode, :streamer_buff

    CLOSING_STREAM_CHAR = "\n"                     # end of message - when streaming to buffer obj
    CHARS_TO_IGNORE     = ["\r"]                   # skip these chars when parsing new message
    FLOATS_ROUND_BY = 2                            # round(x) after summing floats 
    VALID_MESSAGE = /^[\w|\.]+ \d+(?:\.|\d)* \d+$/ # how a valid message should look like
    
    def initialize options
      @options = options
      @keys_to_send  = Hash.new {|h,k| h[k] = []}
      @streamer_buff = Hash.new {|h,k| h[k] = ""}
      @reanimation_mode = !options[:reanimation_exp].nil?
      start_cleaner if reanimation_mode
    end

    def push hash
      debug [:buffer,:add, hash]
      time = Utils.normalize_time(hash[:time],options[:slice])
      hash[:metric].each { |k,v| cache_set(time,k,v) }
    end

    alias_method :<<, :push
    
    def stream message, client_id = nil
      message.each_char do |char|
        next if invalid_char? char
        streamer_buff[client_id] += char 
        
        if closed_stream? streamer_buff[client_id]
          if valid streamer_buff[client_id]
            push build_metric *streamer_buff[client_id].split
          end
          streamer_buff.delete client_id
        end
      end
    end
    
    def pull as = nil
      Array.new.tap do |data|
        keys_to_send.each do |time,keys|
          keys.each do |key|
            data.push cache_get(time, key, as)
          end
        end
        clear
      end
      
    end
    
    def new_records?
      !keys_to_send.empty?
    end
    
    private
    
    def closed_stream? string
      string[-1,1] == CLOSING_STREAM_CHAR
    end
    
    def invalid_char? char
      CHARS_TO_IGNORE.include? char
    end
    
    def cache_set time, key, value
      buffer_cache[time][key] = sum buffer_cache[time][key], value.to_f 
      keys_to_send[time].push key unless keys_to_send[time].include? key
    end
    
    def sum float1, float2
      ("%.#{FLOATS_ROUND_BY}f" % (float1 + float2)).to_f # can't use round on 1.8.X
    end
        
    def cache_get time, key, as
      metric = [prefix + key,buffer_cache[time][key],time]
      as == :string ? metric.join(" ") : metric
    end
        
    def build_metric key, value, time
      { :metric => { key => value },:time => Time.at(time.to_i) }
    end

    def clear
      keys_to_send.clear
      buffer_cache.clear unless reanimation_mode
    end
    
    def valid message
      message =~ VALID_MESSAGE
    end
    
    def prefix
      @prefix ||= options[:prefix].empty? ? '' : prefix_to_s 
    end
    
    def prefix_to_s
      Array(options[:prefix]).join('.') << '.'
    end
    
    def buffer_cache
      @buffer_cache ||= Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = 0}}
    end

    def clean age
      [buffer_cache,keys_to_send].each {|o| o.delete_if {|t,k| Time.now.to_i - t > age}}
    end
    
    def start_cleaner
      Reactor::every(options[:cleaner_interval]) { clean(options[:reanimation_exp]) }
    end

  end
end