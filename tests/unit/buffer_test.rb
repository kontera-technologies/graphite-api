require_relative "../minitest_helper"

module GraphiteAPI
  class BufferTester < Unit::TestCase
    def test_initialize
      assert_raises(ArgumentError) { Buffer.new }

      options = {:shuki => :tuki}

      Buffer.new(options).tap do |buff|
        assert_equal options,  buff.instance_variable_get(:@options)
        assert_kind_of Queue, buff.instance_variable_get(:@queue)
        assert_equal Hash.new, buff.instance_variable_get(:@streamer)
        assert_nil buff.instance_variable_get(:@cache)
      end

      buffer(:cache => 1234).tap do |buff|
        assert_kind_of Cache::Memory, buff.instance_variable_get(:@cache)
      end

    end

    def test_push_avg_with_no_cache
      t1, t2 = [1362559980, 1362568320]
      buffer(:aggregation_method => :avg).tap do |buff|
        buff.push(:metric => {:foo => 10}, :time => t1)
        buff.push(:metric => {:foo => 30}, :time => t1)
        buff.push(:metric => {:foo => 30}, :time => t2)
        buff.push(:metric => {:foo => 40}, :time => t2)
        buff.push(:metric => {:foo => 50}, :time => t2)
        expected = [
          ["foo", 20.0, t1],
          ["foo", 40.0, t2],
        ]
        assert_equal expected, buff.pull
      end
      buffer().tap do |buff|
        buff.push(:metric => {:foo => 10}, :time => t1, :aggregation_method => :avg)
        buff.push(:metric => {:foo => 30}, :time => t1, :aggregation_method => :avg)
        buff.push(:metric => {:foo => 30}, :time => t2, :aggregation_method => :avg)
        buff.push(:metric => {:foo => 40}, :time => t2, :aggregation_method => :avg)
        buff.push(:metric => {:foo => 50}, :time => t2, :aggregation_method => :avg)
        expected = [
          ["foo", 20.0, t1],
          ["foo", 40.0, t2],
        ]
        assert_equal expected, buff.pull
      end
    end

    def test_push_replace_with_no_cache
      t1, t2 = [1362559980, 1362568320]
      buffer(:aggregation_method => :replace).tap do |buff|
        buff.push(:metric => {:foo => 10}, :time => t1)
        buff.push(:metric => {:foo => 30}, :time => t1)
        buff.push(:metric => {:foo => 30}, :time => t2)
        buff.push(:metric => {:foo => 40}, :time => t2)
        buff.push(:metric => {:foo => 50}, :time => t2)
        expected = [
          ["foo", 30.0, t1],
          ["foo", 50.0, t2],
        ]
        assert_equal expected, buff.pull
      end
      buffer().tap do |buff|
        buff.push(:metric => {:foo => 10}, :time => t1, :aggregation_method => :replace)
        buff.push(:metric => {:foo => 30}, :time => t1, :aggregation_method => :replace)
        buff.push(:metric => {:foo => 30}, :time => t2, :aggregation_method => :replace)
        buff.push(:metric => {:foo => 40}, :time => t2, :aggregation_method => :replace)
        buff.push(:metric => {:foo => 50}, :time => t2, :aggregation_method => :replace)
        expected = [
          ["foo", 30.0, t1],
          ["foo", 50.0, t2],
        ]
        assert_equal expected, buff.pull
      end
    end

    def test_push_shouldnt_expose_the_queue
      refute buffer.push(:metric => {:shuki => 10})
    end

    def test_push_with_cache
      buffer(:cache => 100_000).tap do |buff|
        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362568320)
        buff.pull
        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362568320)
        expected = [
          ["shuki",   20.0, 1362568320],
          ["blabla", 160.0, 1362568320]
        ]
        assert_equal expected, buff.pull

        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1234567389)
        buff.push(:metric => {:blabla => 10}, :time => 1362568320)
        expected = [
          ["shuki", 10.0,  1234567380],
          ["blabla", 80.0, 1234567380],
          ["blabla", 170.0, 1362568320]
        ]
        assert_equal expected, buff.pull
      end
    end

    def test_push
      buffer.tap do |buff|
        buff.push(:metric => {:shuki => 10, :blabla => 80})
        expected = [
          ["shuki", 10.0],
          ["blabla", 80.0]
        ]
        assert_equal(expected,buff.pull.map {|o| o[0..1]})

        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565860)
        expected = [
          ["shuki", 10.0, 1362565860],
          ["blabla", 80.0, 1362565860]
        ]
        assert_equal expected, buff.pull

        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565860)
        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565860)
        expected = [
          ["shuki", 20.0, 1362565860],
          ["blabla", 160.0, 1362565860]
        ]
        assert_equal expected, buff.pull

        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565812)
        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565860)
        expected = [
          ["shuki", 10.0, 1362565800],
          ["blabla", 80.0, 1362565800],
          ["shuki", 10.0, 1362565860],
          ["blabla", 80.0, 1362565860]
        ]
        assert_equal expected, buff.pull


        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565812)
        buff.push(:metric => {:shuki => 10}, :time => 1362565812)
        buff.push(:metric => {:shuki => 10, :blabla => 80}, :time => 1362565860)
        expected = [
          ["shuki", 20.0, 1362565800],
          ["blabla", 80.0, 1362565800],
          ["shuki", 10.0, 1362565860],
          ["blabla", 80.0, 1362565860]
        ]
        assert_equal expected, buff.pull

        buff.push(:metric => {:shuki => 1.9, :blabla => 80}, :time => 1362565812)
        buff.push(:metric => {:shuki => 0.2, :blabla => 80.1}, :time => 1362565812)
        expected = [
          ["shuki", 2.1, 1362565800],
          ["blabla", 160.1, 1362565800]
        ]
        assert_equal expected, buff.pull
      end
    end

    def test_stream
      now = 1334850240

      buffer.tap do |buff|
        buff.stream "test.shuki.tuki 123 #{now}"
        buff.stream "\n"
        buff.stream "mem.usage 1"
        buff.stream "90 1326842563\n"
        buff.stream "test.shuki.tuki 123 #{now}\n"
        buff.stream "lo.tov \n"
        buff.stream "lo.tov 112332\n"
        buff.stream "lo."
        buff.stream "tov"
        buff.stream "\n"
        buff.stream "ken.tov 11.2332 231231321\n"
        buff.stream "ken.tovv\t11.2332\t231231321\n"
        buff.stream("client1",:client1)
        buff.stream("client2",:client2)
        buff.stream(" 1",:client1)
        buff.stream(" 2",:client2)
        buff.stream(" 213232\n",:client1)
        buff.stream(" 213232\n",:client2)
        buff.stream("a.b 1211 121212\nc.d 1211 121212\n",:client2)
        buff.stream("test.x 10 1334771088\ntest.z 10 1334771088\n",:client2)
        buff.stream("rabbitmq-monitoring-pack.erans-mbp.search_terms_agg_consume.deliver_rate 319.0 1398605178\n",:client3)
        assert_equal(
          [
            ["test.shuki.tuki",  246.0,  1334850240],
            ["mem.usage",        190.0,  1326842520],
            ["ken.tov",          11.2332,   231231300],
            ["ken.tovv",         11.2332,   231231300],
            ["client1",            1.0,      213180],
            ["client2",            2.0,      213180],
            ["a.b",             1211.0,      121200],
            ["c.d",             1211.0,      121200],
            ["test.x",            10.0,  1334771040],
            ["test.z",            10.0,  1334771040],
            ["rabbitmq-monitoring-pack.erans-mbp.search_terms_agg_consume.deliver_rate", 319.0, 1398605160]
          ],
          buff.pull)

        buff.instance_variable_get(:@streamer).tap do |streamer|
          refute streamer.has_key? nil
          refute streamer.has_key? :client1
          refute streamer.has_key? :client2
        end
      end

    end

    private

    def buffer options = {}
      Buffer.new Client.default_options.merge options
    end

  end
end
