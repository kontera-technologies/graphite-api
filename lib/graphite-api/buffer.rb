require 'thread'

module GraphiteAPI
  class Buffer
    attr_reader :leftovers,:mutex
    
    def initialize
      @leftovers = Hash.new {|h,k| h[k] = Array.new}
      @mutex = Mutex.new
    end
    
    def << hash
      mutex.synchronize do
        time = Utils.normalize_time hash[:time]
        hash[:metric].each { |k,v| buffer[time][k] += v.to_f }
      end
    end
    
    def stream(client_id,data)
      got_leftovers = data[-1,1] != "\n"
      data = data.split(/\n/)
      
      unless leftovers[client_id].empty?
        if (valid leftovers[client_id].last << data.first rescue nil)
          data.unshift(leftovers[client_id].pop << data.shift)
        end
        leftovers[client_id].clear
      end

      leftovers[client_id] << data.pop if got_leftovers
      data.each do |line|
        next unless valid line
        key,val,time = line.split
        self << {:metric => {key => val},:time => (Time.at(time) rescue Time.now)}
      end
    end
    
    def each(&block)
      my_buffer = nil # scoping...
      mutex.synchronize do # locking...
        my_buffer = buffer.clone # copying...
        @buffer = nil # cleaning...
      end
      my_buffer.each {|o| yield o}
    end
      
    def valid(data)
      data =~ /^[\w|\.]+ \d+(?:\.\d)* \d+$/
    end
    
    def empty?
      buffer.empty?
    end
    
    def size
      buffer.values.map(&:values).flatten.size
    end
    
    private    
    def buffer
      @buffer ||= Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = 0}}
    end
    
  end
end