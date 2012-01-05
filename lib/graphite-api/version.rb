module GraphiteAPI
  class Version
    PFILE = File.join(GraphiteAPI::ROOT,"..",".pre_version")
    class << self
      def string
        [0,0,0,pre].join(".")
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