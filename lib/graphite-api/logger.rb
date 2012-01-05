require 'singleton'

module GraphiteAPI
  class Logger
    include Singleton
    
    attr_accessor :logger
    
    def method_missing(m,*args,&block)
      logger.respond_to? m and logger.send(m,*args,&block)
    end
        
  end
end