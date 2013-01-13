# -----------------------------------------------------
# GraphiteAPI Logger
# -----------------------------------------------------
# Usage:
#     Graphite::Logger.logger = ::Logger.new(STDOUT) 
#     Graphite::Logger.info "shuki tuki"
#     Graphite::Logger.debug "hihi"
# 
# Or:
#     Graphite::Logger.init :level => :debug
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
        self.logger.level= ::Logger.const_get "#{options[:level].to_s.upcase}"
      end
      
      def method_missing(m,*args,&block)
        logger.send m, *args, &block if logger.respond_to? m
      end
    end
  end
end
p GraphiteAPI::Logger.init(:level => :debug)
GraphiteAPI::Logger.info "Dsasad"