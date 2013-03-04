module GraphiteAPI
  ROOT = File.expand_path(File.dirname(__FILE__))

  autoload :Version,         "#{ROOT}/graphite-api/version"
  autoload :Client,          "#{ROOT}/graphite-api/client"
  autoload :Cache,           "#{ROOT}/graphite-api/cache"
  autoload :SafeBuffer,      "#{ROOT}/graphite-api/safe_buffer"
  autoload :Reactor,         "#{ROOT}/graphite-api/reactor"
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
  
  Dir.glob( "#{ROOT}/core-extensions/**" ).each &method( :require )
end
