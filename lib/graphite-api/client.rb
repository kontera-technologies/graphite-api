require 'socket'

module GraphiteAPI
  class Client    
    attr_reader :options
    
    def initialize(host,opt = {})
      @options = {
        :host => host,
        :port => 2003,
        :prefix => []
      }.merge opt
      @options[:prefix] = fix_prefix @options[:prefix]
    end
    
    def send_metrics(metrics,opt = {})
      metrics.each do |key,val|
        write message_formater binding
      end
    end
    
    protected
    def fix_prefix(prefix)
      prefix.kind_of?(Array) ? prefix : [prefix]
    end
    
    def message_formater(bind)
      message = options[:prefix].join '.'
      message += "." if options[:prefix].size > 0
      message += "#{eval('key', bind)} "
      message += "#{eval('val',bind).to_f} "
      message += "#{(eval('opt[:time]',bind) || Time.now).to_i}"
      message += "\n"
      message
    end
    
    def write(msg)
      begin
        socket.write(msg << "\n")
      rescue Errno::EPIPE
        @socket = nil
	    retry
      end
    end
    
    def socket
      if @socket.closed? || @socket.nil?
        @socket = TCPSocket.new(*options.values_at(:host,:port))
      end
      @socket
    end
        
  end
end