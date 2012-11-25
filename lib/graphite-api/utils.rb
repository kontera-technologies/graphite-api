module GraphiteAPI
  module Utils
    module ClassMethods
      def attr_private_reader *args
        args.each { |o| attr_reader o or private o }
      end

      def delegate *sources, options
        instance_eval do
          options.fetch(:to).tap do |target|
            sources.each do |source|
              define_method source do |*args, &block|
                if target.is_a? Symbol
                  eval String target 
                else
                  target
                end.send source,*args, &block
              end # define
            end # sources
          end # options
        end # instance_eval
      end # def delegate
    end # ClassMethods
    
    [:info,:error,:warn,:debug].each do |m|
      define_method(m) do |*args,&block|
        Logger.send(m,*args,&block)
      end
    end    
    
    module_function

    def normalize_time time, slice = 60
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
        :reanimation_exp => nil,
        :host => "localhost",
        :prefix => [],
        :interval => 60,
        :slice => 60,
        :pid => "/tmp/graphite-middleware.pid"
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
        File.open(pid,'w') { |f| f.write(Process.pid) } rescue nil
        yield
      end
    end

  end
end