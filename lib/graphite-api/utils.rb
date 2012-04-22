module GraphiteAPI
  module Utils
    
    module_function

    def normalize_time(time,slice = 60)
      ((time || Time.now).to_i / slice * slice).to_i
    end
 
    def expand_host host
      host,port = host.split(":")
      port = port.nil? ? default_options[:port] : port.to_i
      [host,port]
    end

    def default_options
      {
        :backends => [],
        :cleaner_interval => 43200,
        :port => 2003,
        :log_level => :info,
        :cache_exp => nil,
        :host => "localhost",
        :prefix => [],
        :interval => 60,
        :slice => 60,
        :pid => "/var/run/graphite-middleware.pid"
      }
    end
    
    def daemonize pid
      block_given? or raise ArgumentError.new "the block is missing..."
      fork do
        Process.setsid
        exit if fork
        Dir.chdir '/tmp'
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null','a')
        STDERR.reopen('/dev/null','a')
        File.open(pid,'w') { |f| f.write(Process.pid) } rescue
        yield
      end

    end

  end
end