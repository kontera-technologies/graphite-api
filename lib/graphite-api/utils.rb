module GraphiteAPI
  module Utils
    module_function

    def normalize_time(time)
      (time.to_i / 60 * 60).to_i
    end
    
  end
end