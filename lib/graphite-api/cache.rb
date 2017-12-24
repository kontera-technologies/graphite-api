module GraphiteAPI
  module Cache
    class Memory

      def initialize options
        Zscheduler.every(120) { clean(options[:cache]) }
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
        @cache ||= Hash.new {|h,k| h[k] = Hash.new {|h2,k2| h2[k2] = 0}}
      end

      def clean max_age
        Logger.debug [:MemoryCache, :before_clean, cache]
        cache.delete_if {|t,k| Time.now.to_i - t > max_age }
        Logger.debug [:MemoryCache, :after_clean, cache]
      end

    end
  end
end
