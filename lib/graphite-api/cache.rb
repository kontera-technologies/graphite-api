module GraphiteAPI
  module Cache
    autoload :Memory, File.expand_path("../cache/memory", __FILE__)
  end
end