require 'optparse'

module GraphiteAPI
  class Runner
    attr_reader :options

    def initialize(argv)
      parser.parse! argv
      validate_options
    end
    
    def run
      if options[:daemonize]
        fork do
          Process.setsid
          exit if fork
          Dir.chdir('/tmp')
          STDOUT.reopen('/dev/null','a')
          STDIN.reopen('/dev/null')
          STDERR.reopen('/dev/null','a')
          write_pid
          run!
        end
      else
        run!
      end
    end

    private
    def options
      @options ||= Utils.default_options
    end
    
    def write_pid
      begin
        File.open(options[:pid], 'w') { |f| f.write(Process.pid) }
      rescue Exception
      end
    end

    def run!
      GraphiteAPI::Middleware.start(options)
    end

    def validate_options
      abort "You must specify graphite host" if options[:graphite_host].nil?
    end

    def parser
      OptionParser.new do |opts| 
        opts.banner = "Graphite Middleware Server"
        opts.define_head "Usage: graphite-middleware [options]"
        opts.define_head ""
        opts.on("-g", "--graphite HOST","graphite host") {|v| options[:graphite_host] = v}        
        opts.on("-p", "--port PORT","listening port (default 2003)"){|v| options[:listening_port] = v}
        opts.on("-l", "--log-file FILE","log file") {|v| options[:log_file] = File.expand_path(v)}
        opts.on("-L", "--log-level LEVEL","log level (default warn)") {|v|options[:log_level] = v}
        opts.on("-P", "--pid-file FILE","pid file (default /var/run/graphite-middleware.pid)"){|v|options[:pid] = v}
        opts.on("-d", "--daemonize","run in background"){options[:daemonize] = true}
        opts.on("-i", "--interval INT","report every X seconds (default 60)"){|v|options[:interval] = v.to_i unless v.to_i == 0}
        opts.on("-s", "--slice SECONDS","send to graphite in X seconds slices (default is 60)") {|v| options[:slice] = v.to_i unless v.to_i == 0}
        opts.on("-c", "--cache HOURS","cache expiration time in hours (default is 12 hours)") {|v| (options[:cache_exp] = v.to_i * 3600) unless v.to_i == 0}
        opts.define_tail ""
        opts.define_tail ""
      end
    end

  end
end