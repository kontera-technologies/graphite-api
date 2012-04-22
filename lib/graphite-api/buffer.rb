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

    attr_reader :options,:keys_to_send,:reanimation_mode, :streamer_buff

    CLOSING_STREAM_CHAR = "\n"                    # end of message - when streaming to buffer obj
    IGNORING_CHARS      = "\r"                    # remove these chars from message
    FLOATS_ROUND_BY = 2                           # round(x) after joining floats 
    VALID_RECORD = /^[\w|\.]+ \d+(?:\.|\d)* \d+$/ # how a valid record should look like
    
    def initialize options
      @options = options
      @keys_to_send  = Hash.new {|h,k| h[k] = []}
      @streamer_buff = Hash.new {|h,k| h[k] = ""}
      @reanimation_mode = !options[:reanimation_exp].nil?
      start_cleaner if reanimation_mode
    end

    def push hash
      Logger.debug [:buffer,:add,hash]
      time = Utils::normalize_time(hash[:time],options[:slice])
      hash[:metric].each { |k,v| cache_set(time,k,v) }
    end
    alias :<< :push
    
    def stream data, client_id = nil
      data.each_char do |char|
        next if invalid_char? char
        streamer_buff[client_id] += char 
        if char == CLOSING_STREAM_CHAR
          push build_metric(*streamer_buff[client_id].split) if valid streamer_buff[client_id]
          streamer_buff.delete client_id
        end
      end
    end
    
    def pull as = nil
      Array.new.tap do |obj|
        keys_to_send.each { |t, k| k.each { |o| obj.push cache_get(t, o, as) } }
        clear
      end
    end
    
    def empty?
      buffer_cache.empty?
    end

    def got_new_records?
      !keys_to_send.empty?
    end
    
    def size
      buffer_cache.values.map {|o| o.values}.flatten.size
    end # TODO: make it less painful

    private
    def invalid_char?(char)
      IGNORING_CHARS.include?(char)
    end
    
    def cache_set(time, key, value)
      buffer_cache[time][key] = (buffer_cache[time][key] + value.to_f).round(FLOATS_ROUND_BY)
      keys_to_send[time].push(key) unless keys_to_send[time].include?(key)
    end
    
    def cache_get(time, key, as)
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
    
    def valid data
      data =~ /^[\w|\.]+ \d+(?:\.|\d)* \d+$/
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
      [buffer_cache,keys_to_send].each {|o| o.delete_if {|t,k| now - t > age}}
    end
    
    def now
      Time.now.to_i
    end
    
    def start_cleaner
      Scheduler.every(options[:cleaner_interval]) { clean(options[:cache_exp]) }
    end

  end
end