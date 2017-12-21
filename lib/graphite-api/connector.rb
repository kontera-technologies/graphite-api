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
    class Group
      def initialize options
        @connectors = options[:backends].map { |o| Connector.new(*o) }
      end

      def publish messages
        Logger.debug [:connector_group, :publish, messages.size, @connectors]
        Array(messages).each { |msg| @connectors.map {|c| c.puts msg} }
      end
    end
    
    def initialize host, port
      @host, @port = host, port
    end
    
    def puts message
      counter = 0
      begin
        Logger.debug [:connector,:puts,[@host, @port].join(":"),message]
        socket.puts message + "\n"
      rescue Exception
        @socket = nil
        (counter += 1) <= 5 ? retry : raise
      end
    end
    
    def inspect
      "#{self.class} #{@host}:#{@port}"
    end
    
    protected
    
    def socket
      if @socket.nil? || @socket.closed?
        Logger.debug [:connector,[@host,@port]]
        @socket = ::TCPSocket.new @host, @port
      end
      @socket
    end
     
  end
end
