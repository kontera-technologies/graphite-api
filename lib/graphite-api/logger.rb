# -----------------------------------------------------
# GraphiteAPI Logger
# -----------------------------------------------------
# Usage:
#     Graphite::Logger.logger = ::Logger.new(STDOUT) 
#     Graphite::Logger.info "shuki tuki"
#     Graphite::Logger.debug "hihi"
# -----------------------------------------------------
module GraphiteAPI
  class Logger
    class << self
      attr_accessor :logger
      def method_missing(m,*args,&block)
        if logger.respond_to? m then logger.send(m,*args,&block) end
      end      
    end
  end
end