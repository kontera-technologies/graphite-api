# -----------------------------------------------------
# Graphite Middleware Server
# Should be placed between graphite server and graphite clients
# - Data Aggregator
# - Caching
# - Data Manipulation
# -----------------------------------------------------
# Usage:
#   GraphiteAPI::Middleware.start(options)
# 
# Options:
#   graphite_host    target graphite hostname
#   graphite_port    target graphite listening port (default 2003)
#   cache_exp        cache lifetime in seconds  (default is 43200 seconds)
#   prefix           add prefix to each key
#   interval         report to graphite every X seconds (default is 60)
#   slice            send to graphite in X seconds slices (default is 60)
#   log_level        info # TODO: move this to runner.rb
# -----------------------------------------------------
require 'rubygems'
require 'eventmachine'
require 'logger'
require 'socket'

module GraphiteAPI
  class Middleware < EventMachine::Connection

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
      buffer.stream(data,client_id)
    end

    def unbind
      logger.debug "Client disconnecting"
    end

    def self.start(options)
      EventMachine.run do
        # Resources
        GraphiteAPI::Logger.logger = ::Logger.new(options[:log_file] || STDOUT)
        GraphiteAPI::Logger.level = eval "::Logger::#{options[:log_level].to_s.upcase}"
        
        buffer    = GraphiteAPI::Buffer.new(options)
        connector = GraphiteAPI::Connector.new(*options.values_at(:graphite_host,:graphite_port))
        connectors = GraphiteAPI::ConnectorGroup.new(options)
        
        # Starting server
        EventMachine.start_server('0.0.0.0',options[:listening_port],self,GraphiteAPI::Logger.logger,buffer)
        GraphiteAPI::Logger.info "Server running on port #{options[:listening_port]}"
        
        # Send metrics to graphite every X seconds
        GraphiteAPI::Scheduler.every(options[:interval]) do
          if buffer.got_new_records?
            Logger.debug "Sending #{buffer.size} records to graphite (@#{options[:graphite_host]}:#{options[:graphite_port]})"
            buffer.each { |arr| connector.puts arr.join(" ") }
          end # if got_new_records?
          connectors.publish buffer.pull(:string) if buffer.got_new_records?
        end # every 
      end # run 
    end # start
  end # Middleware
end # GraphiteAPI