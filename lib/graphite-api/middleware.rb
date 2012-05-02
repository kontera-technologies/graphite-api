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
#   graphite         target graphite hostname
#   reanimation_exp  cache lifetime in seconds  (default is 43200 seconds)
#   prefix           add prefix to each key
#   interval         report to graphite every X seconds (default is 60)
#   slice            send to graphite in X seconds slices (default is 60)
#   log_level        info 
# -----------------------------------------------------

require 'rubygems'
require 'eventmachine'
require 'logger'
require 'socket'

module GraphiteAPI
  class Middleware < EventMachine::Connection
    include GraphiteAPI::Utils
    
    attr_reader :logger,:buffer,:client_id

    def initialize logger, buffer
      @logger = logger
      @buffer = buffer
      super
    end

    def post_init
      @client_id = Socket.unpack_sockaddr_in(get_peername).reverse.join(":")
      debug [:middleware,:connecting,client_id]
    end

    def receive_data data
      debug [:middleware,:message,client_id,data]
      buffer.stream data, client_id
    end

    def unbind
      debug [:middleware,:disconnecting,client_id]
    end

    def self.start options
      EventMachine.run do
        # Resources
        GraphiteAPI::Logger.logger = ::Logger.new(options[:log_file] || STDOUT)
        GraphiteAPI::Logger.level = eval "::Logger::#{options[:log_level].to_s.upcase}"
        # TODO: move logger logic to runner
        
        buffer    = GraphiteAPI::Buffer.new(options)
        connectors = GraphiteAPI::ConnectorGroup.new(options)
        
        # Starting server
        EventMachine.start_server('0.0.0.0',options[:port],self,GraphiteAPI::Logger.logger,buffer)
        GraphiteAPI::Logger.info "Server running on port #{options[:port]}"
        
        # Send metrics to graphite every X seconds
        GraphiteAPI::Scheduler.every( options[:interval] ) do
          EventMachine::defer(proc { buffer.pull(:string) }, proc {|r| connectors.publish(r)} ) if buffer.new_records?
        end # every 
        
      end # run 
    end # start
  end # Middleware
end # GraphiteAPI