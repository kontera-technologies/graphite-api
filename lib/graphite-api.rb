require 'zscheduler'
require 'graphite-api/version'
require 'graphite-api/client'
require 'graphite-api/cache'
require 'graphite-api/connector'
require 'graphite-api/buffer'
require 'graphite-api/logger'

module GraphiteAPI

  def self.version
    GraphiteAPI::VERSION
  end

  def self.new options
    Client.new options
  end

end
