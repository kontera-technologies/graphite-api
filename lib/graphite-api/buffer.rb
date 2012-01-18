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
#     buff.each {|o| p o} 
#
# Produce:
#   ["load_avg", 40.0, 1326881160]
#   ["mem.usage", 190.0, 1326842520]
#   ["shuki.tuki", 999.0, 1326842520]
# -----------------------------------------------------
module GraphiteAPI
  class Buffer
    attr_reader :leftovers,:options,:new_records,:in_cache_mode

    def initialize(options)
      @options = options
      @leftovers = Hash.new {|h,k| h[k] = Array.new}
      @new_records = []
      @in_cache_mode = !options[:cache_exp].nil?
      start_cleaner if in_cache_mode
    end

    def << hash
      time = Utils.normalize_time(hash[:time],options[:slice])
      hash[:metric].each do |k,v|
        buffer[time][k] += v.to_f
        new_records << [time,k]
      end
    end

    def stream(data,client_id = nil)
      got_leftovers = data[-1,1] != "\n"
      data = data.split(/\n/)
      unless leftovers[client_id].empty?
        if (valid leftovers[client_id].last + data.first rescue nil)
          data.unshift(leftovers[client_id].pop + data.shift)
        end
        leftovers[client_id].clear
      end

      leftovers[client_id] << data.pop if got_leftovers
      data.each do |line|
        next unless valid line
        key,val,time = line.split
        self << {:metric => {key => val},:time => (Time.at(time.to_i) rescue Time.now)}
      end
    end

    def each
      new_records.uniq.each do |time,key|
        yield [prefix + key,buffer[time][key],time]
      end and clear
    end
    
    def empty?
      buffer.empty?
    end

    def got_new_records?
      !new_records.empty?
    end

    def size
      buffer.values.map(&:values).flatten.size
    end

    private
    def clear
      new_records.clear
      buffer.clear unless in_cache_mode
    end
    
    def valid(data)
      data =~ /^[\w|\.]+ \d+(?:\.\d)* \d+$/
    end
    
    def prefix
      @prefix ||= options[:prefix].empty? ? String.new : prefix_to_s 
    end
    
    def prefix_to_s
      [options[:prefix]].flatten.join('.') << "."
    end
    
    def buffer
      @buffer ||= Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = 0}}
    end

    def clean(age)
      [buffer,new_records].each {|o| o.delete_if {|t,k| now - t > age}}
    end
    
    def now
      Time.now.to_i
    end
    
    def start_cleaner
      Scheduler.every(options[:cleaner_interval]) { clean options[:cache_exp] }
    end

  end
end