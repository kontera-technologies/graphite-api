$:.unshift File.expand_path("../../lib",__FILE__)

require 'simplecov'
require 'simplecov-rcov'
require 'codecov'

SimpleCov.start { add_filter "/tests/" }
SimpleCov.formatter = Class.new do
  def format(result)
     SimpleCov::Formatter::Codecov.new.format(result) if ENV["CODECOV_TOKEN"]
     SimpleCov::Formatter::RcovFormatter.new.format(result) unless ENV["CI"]
  end
end

require 'minitest'
require 'minitest/autorun'
require "mocha/minitest"

require_relative "../lib/graphite-api"

module GraphiteAPI

  class BaseTestCase < Minitest::Test
    def teardown
      teardown_threads
    end

    def teardown_threads
      Thread.list.each do |thread|
        thread.exit unless thread == Thread.current
      end
    end
  end

  class UnitTestCase < BaseTestCase
  end

  class FunctionalTestCase < BaseTestCase
    def random_non_repeating_port
      @ports ||= (1000..9999).to_a.shuffle
      @ports.pop
    end

    def stop_em_if_running
      EM.stop if EM.reactor_running?
      sleep 0.1 while EM.reactor_running?
    end
  end

  module MockServer
    def initialize db
      @db = db
    end
    def receive_data data
      @db.push data
    end
  end
end
