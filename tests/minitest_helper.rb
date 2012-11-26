if ENV['with_coverage']
  require 'simplecov'
  require 'simplecov-rcov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
       SimpleCov::Formatter::HTMLFormatter.new.format(result)
       SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end

  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
  SimpleCov.start { add_filter "/tests/" }
end

require 'minitest/autorun'
require 'turn/autorun'
require 'mocha'

require_relative "../lib/graphite-api"

module GraphiteAPI
  module Unit
    class TestCase < ::Minitest::Unit::TestCase
    end
  end
end