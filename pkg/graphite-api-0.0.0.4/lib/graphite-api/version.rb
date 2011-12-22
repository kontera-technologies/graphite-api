module GraphiteAPI
  class Version
    PFILE = File.join(GraphiteAPI::ROOT,"..",".gem_pre_version")
    
    MAJOR = 0
    MINOR = 0
    BUILD = 0
    
    class << self
      def string
        [MAJOR,MINOR,BUILD,pre].join(".")
      end

      def increment_pre
        new_version = pre + 1
        File.open(PFILE,"w") { |f| f.puts new_version }
      end

      private
      def pre
        File.read(PFILE).to_i
      end
      
    end
    
  end
end