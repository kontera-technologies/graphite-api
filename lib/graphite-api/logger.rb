require 'singleton'

module GraphiteAPI
  class Logger
    include Singleton
    
    class << self
      attr_accessor :logger
    end
    
    def method_missing(m,*args,&block)
      if logger.respond_to? m then logger.send(m,*args,&block) end
    end
    
    def logger
      self.class.logger
    end
    
  end
end