module GraphiteAPI
  module Cache
    class Memory

      def initialize options
        Reactor.every(60) { clean(options[:age]) }
      end
      
      def get time, key
        cache[time][key]
      end
      
      def set time, key, value
        cache[time][key] = value.to_f 
      end
      
      def incr *args
        set(value.to_f + get(*args))
      end
      
      private
      
      def cache
        @cache ||= Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = 0}}
      end
      
      def clean age
        cache.delete_if {|t,k| Time.now.to_i - t > age}
      end
      
    end
  end
end