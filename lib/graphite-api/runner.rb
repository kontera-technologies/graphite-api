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
        :port => 2003,
        :pid => "/var/run/graphite-middleware.pid",
        :log_level => Logger::WARN,
      }
      parser.parse! argv
      validate_options
    end

    def run
      if options[:daemonize]
        fork do
          write_pid
          Process.setsid
          exit if fork
          Dir.chdir('/tmp')
          STDOUT.reopen('/dev/null','a')
          STDIN.reopen('/dev/null')
          STDERR.reopen('/dev/null','a')
          run!
        end
      else
        run!
      end

    end

    private

    def run!
      GraphiteAPI::Middleware.start(options)
    end

    def write_pid
      begin;File.open(options[:pid], 'w') { |file| file.write(Process.pid) };rescue;end
    end

    def validate_options
      abort "You must specify graphite host" if options[:graphite_host].nil?
    end

    def parser
      OptionParser.new do |opts| 
        opts.banner = "Graphite Middleware Server"
        opts.define_head "Usage: graphite-middleware [options]"
        opts.define_head ""

        opts.on("-p", "--port PORT","listening port (default 2003)") do |val|
          options[:port] = val
        end

        opts.on("-g", "--graphite HOST","graphite host") do |val|
          options[:graphite_host] = val
        end
        
        opts.on("-l", "--log-file FILE","log file") do |val|
          options[:log_file] = File.expand_path(val)
        end
        
        opts.on("-L", "--log-level LEVEL","log level (default warn)") do |val|
          options[:log_level] = eval("Logger::#{val.upcase}")
        end

        opts.on("-P", "--pid-file FILE","pid file (default /var/run/graphite-middleware.pid)") do |val|
          options[:pid] = val
        end

        opts.on("-d", "--daemonize","run in backgroud") do 
          options[:daemonize] = true
        end

        opts.on("-i", "--interval INT","report every X seconds") do |val|
          options[:interval] = val.to_i unless val.to_i == 0
        end

        opts.define_tail ""
        opts.define_tail ""
      end
    end

  end
end
