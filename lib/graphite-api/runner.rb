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
       Middleware::start options
    end

    def options
      @options ||= Utils::default_options
    end

    def validate_options
      abort "You must specify at least one graphite host" if options[:backends].empty?
    end

  end
end
