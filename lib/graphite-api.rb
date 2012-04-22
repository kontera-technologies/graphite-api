module GraphiteAPI
  ROOT = File.expand_path(File.dirname(__FILE__))

  autoload :Version,         "#{ROOT}/graphite-api/version"
  autoload :Client,          "#{ROOT}/graphite-api/client"
  autoload :Scheduler,       "#{ROOT}/graphite-api/scheduler"
  autoload :Connector,       "#{ROOT}/graphite-api/connector"
  autoload :Middleware,      "#{ROOT}/graphite-api/middleware"
  autoload :Runner,          "#{ROOT}/graphite-api/runner"
  autoload :Utils,           "#{ROOT}/graphite-api/utils"
  autoload :CLI,             "#{ROOT}/graphite-api/cli"
  autoload :Buffer,          "#{ROOT}/graphite-api/buffer"
  autoload :Logger,          "#{ROOT}/graphite-api/logger"
  autoload :ConnectorGroup,  "#{ROOT}/graphite-api/connector_group"

  def self.version
    GraphiteAPI::Version::VERSION
  end
  
end
