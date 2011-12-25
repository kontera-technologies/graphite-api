module GraphiteAPI
  class Client
    attr_reader :options,:buffer,:connector
    
    def initialize(host,opt = {})
      @buffer = []
      @options = {
        :host => host,
        :port => 2003,
        :prefix => [],
        :interval => 60
      }.merge opt
      @options[:prefix] = [@options[:prefix]] unless @options[:prefix].kind_of?(Array)
      @connector = Connector.new(*options.values_at(:host,:port))
      Scheduler.every(options[:interval]) {send_metrics}
    end

    def add_metrics(m)
      buffer << m
    end

    protected
    def send_metrics
      time = Time.now.to_i
      buffer.each do |hash|
        hash.each do |key,val|
          connector.puts "#{prefix_str(options[:prefix])}#{key} #{val.to_f} #{time}"
        end
      end
      buffer.clear
    end

    def prefix_str(prefix)
      "#{prefix.join('.')}#{'.' if !prefix.empty?}"
    end
    
  end
end

require File.join(File.dirname(__FILE__),"..","graphite-api")
c = GraphiteAPI::Client.new("127.0.0.1",:prefix => ["kontera","prefix","test"],:port => 2004,:interval => 1)
i = 0
while true
  i +=1
  c.add_metrics("shuki#{rand 10}" => rand(999))
  sleep 0.0001
  break if i == 1000000
end
sleep 100