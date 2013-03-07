require 'optparse'

module GraphiteAPI
  class CLI
    
    def self.parse(argv, options)
      OptionParser.new do |opts| 
        opts.banner = "GraphiteAPI Middleware Server"
        opts.define_head "Usage: graphite-middleware [options]"
        opts.define_head ""

        opts.on("-g", "--graphite HOST:PORT","graphite host, in HOST:PORT format (can be specified multiple times)") do |graphite|
          options[:backends] << Utils::expand_host(graphite)
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

        opts.on("-r", "--reanimation HOURS","reanimate records that are younger than X hours, please see README") do |exp|
          (options[:cache] = exp.to_i * 3600) if exp.to_i > 0
        end
        
        opts.on("-v", "--version","Show version and exit") do |exp|
          puts "Version #{GraphiteAPI.version}" 
          exit
        end

        opts.separator ""
        opts.separator "More Info @ https://github.com/kontera-technologies/graphite-api"
        opts.separator ""

        opts.define_tail ""
        opts.define_tail ""
      end.parse! argv
      options
    end
  end
end