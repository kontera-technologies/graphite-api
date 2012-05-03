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
require 'socket'

module GraphiteAPI
  class Middleware < EventMachine::Connection
    include GraphiteAPI::Utils
    
    attr_reader :logger,:buffer,:client_id

    def initialize buffer
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
        buffer = GraphiteAPI::Buffer.new(options)
        connectors = GraphiteAPI::ConnectorGroup.new(options)
        
        # Starting server
        EventMachine.start_server('0.0.0.0',options[:port],self,buffer)
        GraphiteAPI::Logger.info "Server running on port #{options[:port]}"
        
        # Send metrics to graphite every X seconds
        GraphiteAPI::Reactor::every( options[:interval] ) do
          connectors.publish buffer.pull(:string) if buffer.new_records?
        end # every 
        
        GraphiteAPI::Reactor::add_shutdown_hook do           
          connectors.publish buffer.pull(:string)
        end
        
      end # run 
    end # start
  end # Middleware
end # GraphiteAPI