require 'socket'

module GraphiteAPI
  class Client
    
    attr_reader :options
    
    def initialize(host,opt = {})
      @options = {
        :host => host,
        :port => 2003,
        :prefix => ""
      }.merge opt
    end
    
    def send_metrics(metrics,opt = {})
      
    end
    
    protected
    def socket
      if @socket.closed? || @socket.nil?
        @socket = TCPSocket.new(@host,@port)
      end
      @socket
    end
    
    def write(msg)
      socket.write msg
    end
    
  end
end