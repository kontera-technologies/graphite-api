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
    include Utils
    
    def initialize host, port
      @host = host
      @port = port
    end
    
    private_reader :host, :port
    
    def puts message
      begin
        debug [:connector,:puts,[host,port].join(":"),message]
        socket.puts message + "\n"
      rescue Errno::EPIPE, Errno::EINVAL
        @socket = nil
      retry
      end
    end
    
    def inspect
      "#{self.class} #{@host}:#{@port}"
    end
    
    protected
    
    def socket
      if @socket.nil? || @socket.closed?
        @socket = ::TCPSocket.new host, port
      end
      @socket
    end
     
  end
end
