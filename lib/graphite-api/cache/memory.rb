module GraphiteAPI
  module Cache
    class Memory
      include Utils
      
      def initialize options
        Reactor.every(120) { clean(options[:cache]) }
      end
      
      def get time, key
        cache[time.to_i][key]
      end
      
      def set time, key, value
        cache[time.to_i][key] = value.to_f 
      end
      
      def incr time, key, value
        set(time, key, value.to_f + get(time, key))
      end
      
      private
      
      def cache
        @cache ||= nested_zero_hash
      end
      
      def clean max_age
        debug [:MemoryCache, :before_clean, cache]
        cache.delete_if {|t,k| Time.now.to_i - t > max_age }
        debug [:MemoryCache, :after_clean, cache]
      end
      
    end
  end
end