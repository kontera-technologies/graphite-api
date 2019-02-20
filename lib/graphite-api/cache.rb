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
        cache[time.to_i][key] = value
      end

      private

      def cache
        @cache ||= Hash.new {|h,k| h[k] = Hash.new}
      end

      def clean max_age
        Logger.debug [:MemoryCache, :before_clean, cache]
        cache.delete_if {|t,k| Time.now.to_i - t > max_age }
        Logger.debug [:MemoryCache, :after_clean, cache]
      end

    end
  end
end
