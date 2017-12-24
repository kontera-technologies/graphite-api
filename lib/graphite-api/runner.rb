require 'optparse'

module GraphiteAPI
  class Runner
    
    def initialize argv
      CLI.parse argv, options
      validate_options
    end
    
    def run
      Logger.init Hash[[:dev,:level].zip options.values_at(:log_file, :log_level) ]
      options[:daemonize] ? daemonize(options[:pid], &method(:run!)) : run!
    end

    private
    
    def daemonize pid, &block
      block_given? or raise ArgumentError.new "the block is missing..."

      fork do
        Process.setsid
        exit if fork
        Dir.chdir '/tmp'
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null','a')
        STDERR.reopen('/dev/null','a')
        File.open(pid,'w') { |f| f.write(Process.pid) } rescue nil
        block.call
      end
    end
    
    def run!
      begin
        Middleware.start options
      rescue Interrupt
        Logger.info "Shutting down..."
        Zscheduler.stop
      end
    end

    def options
      @options ||= Client::DEFAULT_OPTIONS.merge interval: 60
    end

    def validate_options
      abort "You must specify at least one graphite host" if options[:backends].empty?
    end

  end
end
