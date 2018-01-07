require 'socket'
require 'uri'

module GraphiteAPI
  class Connector

    class UDPSocket
      def initialize uri
        @uri = uri
        @socket = ::UDPSocket.new
      end

      def puts message
        @socket.send message, 0, @uri.host, @uri.port
      end

      def closed?
        @socket.closed? rescue true
      end
    end

    class TCPSocket
      def initialize uri
        @uri = uri
      end

      def puts message
        socket.puts message
      end

      def closed?
        socket.closed? rescue true
      end

      def socket
        @socket ||= begin
          host, port = @uri.host, @uri.port
          timeout = Hash[URI.decode_www_form(@uri.query.to_s)].fetch("timeout", 1).to_f
          addr = Socket.getaddrinfo host, nil, :INET
          sockaddr = Socket.pack_sockaddr_in port, addr[0][3]

          sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
          sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
          begin
            sock.connect_nonblock sockaddr
          rescue IO::WaitWritable
            if IO.select nil, [sock], nil, timeout
              begin
                sock.connect_nonblock sockaddr
              rescue Errno::EISCONN # success
              rescue
                sock.close
                raise
              end
            else
              sock.close
              raise "Connection timeout"
            end
          end
          sock
        end #begin

      end # Socket
    end # TCPSocket

    class Group
      def initialize options
        @connectors = options[:backends].map(&Connector.method(:new))
      end

      def publish messages
        Logger.debug [:connector_group, :publish, messages.size, @connectors]
        Array(messages).each { |msg| @connectors.map {|c| c.puts msg} }
      end
    end

    ##############################################################################

    def initialize uri
      @uri = URI.parse uri
      @uri = @uri.host ? @uri : URI.parse("udp://#{uri}")
    end

    def puts message
      counter = 0
      begin
        Logger.debug [:connector, :puts, @uri.to_s, message]
        socket.puts message + "\n"
      rescue Exception
        @socket = nil
        (counter += 1) <= 5 ? retry : raise
      end
    end

    def inspect
      "#<#{self.class}:#{object_id}: #{@uri}>"
    end

    private 

    def socket
      if @socket.nil? || @socket.closed?
        @socket = @uri.scheme.eql?("tcp") ? TCPSocket.new(@uri) : UDPSocket.new(@uri)
      end
      @socket
    end

  end
end
