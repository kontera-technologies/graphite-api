require 'optparse'
require 'logger'

module GraphiteAPI
  class Runner
    attr_reader :options

    def initialize(argv)
      @options = {
        :graphite_host => "127.0.0.1",
        :graphite_port => 2003,
        :port => 2003,
        :log_level => Logger::WARN,
        :interval => 60,
        :pid => "/var/run/graphite-middleware.pid"
      }
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
        opts.on("-p", "--port PORT","listening port (default 2003)"){|v| options[:port] = v}
        opts.on("-g", "--graphite HOST","graphite host") {|v| options[:graphite_host] = v}
        opts.on("-l", "--log-file FILE","log file") {|v| options[:log_file] = File.expand_path(v)}
        opts.on("-L", "--log-level LEVEL","log level (default warn)") {|v|options[:log_level] = eval("Logger::#{v.upcase}")}
        opts.on("-P", "--pid-file FILE","pid file (default /var/run/graphite-middleware.pid)"){|v|options[:pid] = v}
        opts.on("-d", "--daemonize","run in background"){options[:daemonize] = true}
        opts.on("-i", "--interval INT","report every X seconds"){|v|options[:interval] = v.to_i unless v.to_i == 0}
        opts.define_tail ""
        opts.define_tail ""
      end
    end

  end
end