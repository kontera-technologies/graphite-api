# -----------------------------------------------------
# TCP Socket connection
# -----------------------------------------------------
# Usage:
#    connector = GraphiteAPI::Connector.new("localhost",2003)
#    connector.puts("my.metric 1092 1232123231")
#
# Socket:
# => my.metric 1092 1232123231\n
# -----------------------------------------------------
require 'socket'
module GraphiteAPI
  class Connector
    attr_reader :options
    
    def initialize(host,port)
      @host = host
      @port = port
    end
    
    def puts(msg)
      begin
        Logger.debug msg
        socket.puts(msg)
      rescue Errno::EPIPE
        @socket = nil
      retry
      end
    end
    
    protected
    
    def socket
      if @socket.nil? || @socket.closed?
        @socket = TCPSocket.new(@host,@port)
      end
      @socket
    end
     
  end
end