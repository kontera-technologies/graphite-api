require 'optparse'

module GraphiteAPI
  class Runner
        
    def initialize(argv)
      GraphiteAPI::CLI::parse(argv,options)
      validate_options
    end
    
    def run
      options[:daemonize] ? daemonize(options[:pid]) { run! } : run!
    end

    private
    
    def run!
      GraphiteAPI::Logger.init(:std => options[:log_file], :level => options[:log_level])
      begin
        Middleware::start options
      rescue Interrupt
        GraphiteAPI::Logger.info "Shutting down..."
        GraphiteAPI::Reactor::stop
      end
    end

    def options
      @options ||= Utils::default_options
    end

    def validate_options
      abort "You must specify at least one graphite host" if options[:backends].empty?
    end

  end
end
