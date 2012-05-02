# -----------------------------------------------------
# GraphiteAPI Logger
# -----------------------------------------------------
# Usage:
#     Graphite::Logger.logger = ::Logger.new(STDOUT) 
#     Graphite::Logger.info "shuki tuki"
#     Graphite::Logger.debug "hihi"
# -----------------------------------------------------
require 'logger'

module GraphiteAPI
  class Logger
    class << self
      attr_accessor :logger
      
      # :level => :debug
      # :std => out|err|file-name
      def init(options)
        self.logger = ::Logger.new(options[:std] || STDOUT)
        self.logger.level= eval "::Logger::#{options[:level].to_s.upcase}"
      end
      
      def method_missing(m,*args,&block)
        if logger.respond_to? m then logger.send(m,*args,&block) end
      end      
    end
  end
end