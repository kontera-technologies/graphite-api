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

    def self.start(options)
      EM.run do
        # Resources
        logger = ::Logger.new(options[:log_file] || STDOUT)
        logger.level = eval("::Logger::#{options[:log_level].to_s.upcase}")
        buffer = GraphiteAPI::Buffer.new(options)
        connector = GraphiteAPI::Connector.new(*options.values_at(:graphite_host,:graphite_port))
        GraphiteAPI::Logger.instance.logger = logger
        
        # Starting server
        EM.start_server('0.0.0.0',options[:listening_port],self,logger,buffer)
        logger.info "Server running on port #{options[:listening_port]}"
        
        # Send metrics to graphite every X seconds
        GraphiteAPI::Scheduler.every(options[:interval]) do
          if buffer.got_new_records?
            logger.debug "Sending #{buffer.size} records to graphite (@#{options[:graphite_host]}:#{options[:graphite_port]})"
            buffer.each do |arr| 
              line = arr.join(" ")
              logger.debug line
              connector.puts line
            end # each
          end # if got_new_records?
        end # every 
      end # run 
    end # start
  end # Middleware
end # GraphiteAPI