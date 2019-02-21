require 'socket'
require 'uri'

module GraphiteAPI
  class Connector
    attr_reader :uri

    def initialize uri
      @uri = URI.parse uri
      @uri = @uri.host ? @uri : URI.parse("udp://#{uri}")
      @socket = nil
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

    # Manually init Socket, exception will be thrown on error
    def check!
      socket; nil
    end

    private

    def socket
      if @socket.nil? || @socket.closed?
        @socket = @uri.scheme.eql?("tcp") ? init_tcp : init_udp
      end

      @socket
    end

    def init_tcp
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
    end

    def init_udp
      UDPSocket.new.tap {|x| x.connect @uri.host, @uri.port }
    end

    class Group
      def initialize options
        @connectors = options[:backends].map(&Connector.method(:new))
      end

      def publish messages
        Logger.debug [:connector_group, :publish, messages.size, @connectors]
        Array(messages).each { |msg| @connectors.map {|c| c.puts msg} }
      end

      # init all sockets in group.
      # should throw exception on Socket errors.
      def check!
        @connectors.each do |c|
          begin
            c.check!
          rescue Exception => e
            raise e, "#{c.uri}: #{e.message}", e.backtrace
          end
        end
      end
    end

  end
end
