require 'optparse'

module GraphiteAPI
  class Runner
    include Utils

    attr_reader :options

    def initialize(argv)
      parser.parse! argv
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

    def parser
      OptionParser.new do |opts| 
        opts.banner = "Graphite Middleware Server"
        opts.define_head "Usage: graphite-middleware [options]"
        opts.define_head ""

        opts.on("-g", "--graphite HOST:PORT","graphite host, in HOST:PORT format") do |graphite|
          options[:backends] << expand_host(graphite)
        end

        opts.on("-p", "--port PORT","listening port (default #{options[:port]})") do |port|
          options[:port] = port
        end

        opts.on("-l", "--log-file FILE","log file") do |file|
          options[:log_file] = File::expand_path(file)
        end

        opts.on("-L", "--log-level LEVEL","log level (default warn)") do |level|
          options[:log_level] = level
        end

        opts.on("-P", "--pid-file FILE","pid file (default #{options[:pid]})") do |pid_file|
          options[:pid] = pid_file
        end

        opts.on("-d", "--daemonize","run in background") do 
          options[:daemonize] = true
        end

        opts.on("-i", "--interval INT","report every X seconds (default #{options[:interval]})") do |x_seconds|
          options[:interval] = x_seconds.to_i if x_seconds.to_i > 0
        end

        opts.on("-s", "--slice SECONDS","send to graphite in X seconds slices (default #{options[:slice]})") do |slice|
          options[:slice] = slice.to_i if slice.to_i >= 0
        end

        opts.on("-c", "--cache HOURS","cache expiration time in hours (default is 12 hours)") do |exp| 
          (options[:cache_exp] = exp.to_i * 3600) if exp.to_i > 0
        end

        opts.define_tail ""
        opts.define_tail ""
      end
    end
  end
end
