module GraphiteAPI
  module Utils
    module_function

    def normalize_time(time,slice = 60)
      ((time || Time.now).to_i / slice * slice).to_i
    end
    
    def default_options
      {
        :cleaner_interval => 43200,
        :graphite_port => 2003,
        :listening_port => 2003,
        :log_level => :info,
        :cache_exp => nil,
        :host => "localhost",
        :port => 2003,
        :prefix => [],
        :interval => 60,
        :slice => 60,
        :pid => "/var/run/graphite-middleware.pid"
      }
    end
    
  end
end