require 'rubygems'
require 'eventmachine'
require 'logger'

module GraphiteAPI
  class Middleware < EM::Connection

    attr_reader :logger,:buffer,:leftovers

    def initialize(logger,buffer)
      @logger = logger
      @buffer = buffer
      super
    end

    def post_init
      logger.debug "Client connecting"
      @leftovers = []
    end

    def receive_data(data)
      got_leftovers = data[-1] != "\n"
      data = data.split(/\n/)
      
      unless leftovers.empty?
        if valid leftovers.last.to_s + data.first.to_s
          data.unshift(leftovers.pop + data.shift)
        end
        leftovers.clear
      end

      leftovers << data.pop if got_leftovers
      buffer.concat data
    end

    def unbind
      logger.debug "Client disconnecting"
    end

    def self.start(opt)
      EM.run do  
        # Resources
        logger  = Logger.new(opt[:log_file] || STDOUT)
        logger.level = opt[:log_level]
        buffer  = Array.new
        connector = Connector.new(*opt.values_at(:graphite_host,:graphite_port))

        # Starting server
        EM.start_server('0.0.0.0',opt[:port],self,logger,buffer)
        logger.info "Server running on port #{opt[:port]}"

        # Send metrics to graphite every X seconds
        GraphiteAPI::Scheduler.every(opt[:interval]) do
          unless buffer.empty?
            buffer.flatten!
            logger.debug "Sending #{buffer.size} records to graphite (@#{opt[:graphite_host]}:#{opt[:graphite_port]})"
            now = Time.now.to_i
            obj = Hash.new {|h,k| h[k] = 0}
            buffer.each do |val|
              key,val = val.scan(/([\w|\.]+) (\d+(?:\.\d)*) (\d+)$/).flatten
              obj[key] += val.to_f
            end
            logger.debug "After Aggregation #{obj.size} records (reduced #{buffer.size - obj.size})"
            obj.map {|o| "#{o[0]} #{o[1]} #{now}"}.each {|o| connector.puts o}
            buffer.clear
          end
        end

      end
    end

    private
    def valid(data)
      data =~ /^[\w|\.]+ \d+(?:\.\d)* \d+$/
    end

  end
end