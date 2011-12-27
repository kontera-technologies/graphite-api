module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector

    def initialize(host,opt = {})
      @buffer = Hash.new {|h,k| h[k] = []}
      @options = {
        :host => host,
        :port => 2003,
        :prefix => [],
        :interval => 60,
        :aggregate => true
        }.merge opt
        @options[:prefix] = [@options[:prefix]] unless @options[:prefix].kind_of?(Array)
        @connector = Connector.new(*options.values_at(:host,:port))
        GraphiteAPI::Scheduler.every(options[:interval]) {send_metrics}
      end

      def add_metrics(m,time = Time.now)
        buffer[Utils.normalize_time(time)] << m
      end
      
      def join
        GraphiteAPI::Scheduler.join
      end

      def every(frequency,&block)
        GraphiteAPI::Scheduler.every(frequency,&block)
      end

      def stop
        GraphiteAPI::Scheduler.stop
      end

      protected
      
      def send_metrics
        records = []
        while !(record = buffer.shift).empty?
          records << record
        end
        records = aggregate_records(records) if options[:aggregate]
        records.each do |time,arr_metrics|
          arr_metrics.each do |metrics|
            prefix = prefix_str options[:prefix]
            metrics.each do |key,val|
              connector.puts "#{prefix}#{key} #{val.to_f} #{time}"
            end
          end
        end
      end

      def aggregate_records(records)
        obj = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = 0}}
        records.each do |time,arr_metrics|
          arr_metrics.each do |metrics|
            metrics.each do |key,val|
              obj[time][key] += val.to_f
            end
          end
        end
        obj.each {|t,h| obj[t] = [h]}
      end

      def prefix_str(prefix)
        "#{prefix.join('.')}#{'.' if !prefix.empty?}"
      end

    end
end