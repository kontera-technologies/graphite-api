require 'zscheduler'

module GraphiteAPI
  ROOT = File.expand_path File.dirname __FILE__

  require "#{ROOT}/graphite-api/version"

  autoload :Version,    "#{ROOT}/graphite-api/version"
  autoload :Client,     "#{ROOT}/graphite-api/client"
  autoload :Cache,      "#{ROOT}/graphite-api/cache"
  autoload :Connector,  "#{ROOT}/graphite-api/connector"
  autoload :Middleware, "#{ROOT}/graphite-api/middleware"
  autoload :Runner,     "#{ROOT}/graphite-api/runner"
  autoload :Utils,      "#{ROOT}/graphite-api/utils"
  autoload :CLI,        "#{ROOT}/graphite-api/cli"
  autoload :Buffer,     "#{ROOT}/graphite-api/buffer"
  autoload :Logger,     "#{ROOT}/graphite-api/logger"

  def self.version
    GraphiteAPI::VERSION
  end
  
end
