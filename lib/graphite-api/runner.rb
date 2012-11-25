require 'optparse'

module GraphiteAPI
  class Runner
    include Utils
    
    def initialize argv
      CLI.parse argv, options
      validate_options
    end
    
    def run
      Logger.init Hash[[:std,:level].zip options.values_at(:log_file, :log_level) ]
      options[:daemonize] ? daemonize(options[:pid]) { run! } : run!
    end

    private
    
    def run!
      begin
        Middleware.start options
      rescue Interrupt
        Logger.info "Shutting down..."
        Reactor.stop
      end
    end

    def options
      @options ||= Utils.default_options
    end

    def validate_options
      abort "You must specify at least one graphite host" if options[:backends].empty?
    end

  end
end
