module GraphiteAPI
  module Utils
    module_function

    def normalize_time(time,interval = 60)
      (time.to_i / interval * interval).to_i
    end
    
  end
end