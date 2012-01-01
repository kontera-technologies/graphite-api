require 'rubygems'
require 'eventmachine'
require 'logger'
require 'socket'

module GraphiteAPI
  class Middleware < EM::Connection

    attr_reader :logger,:buffer,:client_id

    def initialize(logger,buffer)
      @logger = logger
      @buffer = buffer
      super
    end

    def post_init
      logger.debug "Client connecting"
      @client_id = Socket.unpack_sockaddr_in(get_peername).join(":")
    end

    def receive_data(data)
      buffer.stream(client_id,data)
    end

    def unbind
      logger.debug "Client disconnecting"
    end

    def self.start(opt)
      EM.run do  
        # Resources
        logger = ::Logger.new(opt[:log_file] || STDOUT)
        buffer = GraphiteAPI::Buffer.new
        connector = GraphiteAPI::Connector.new(*opt.values_at(:graphite_host,:graphite_port))
        logger.level = opt[:log_level]

        # Starting server
        EM.start_server('0.0.0.0',opt[:port],self,logger,buffer)
        logger.info "Server running on port #{opt[:port]}"
        
        # Send metrics to graphite every X seconds
        GraphiteAPI::Scheduler.every(opt[:interval]) do
          unless buffer.empty?            
            logger.debug "Sending #{buffer.size} records to graphite (@#{opt[:graphite_host]}:#{opt[:graphite_port]})"
            buffer.each do |time,metrics|
              metrics.map {|k,v| "#{k} #{v} #{time}"}.each {|o| logger.debug o;connector.puts o}
            end # each metric
          end # unless empty?
        end # every 
      end # run 
    end # start
  end # Middleware
end # GraphiteAPI