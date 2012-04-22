=begin
require '../graphite-api'
instance = GraphiteAPI::Buffer.new()
instance << {:metric => {'a' => 10},:time => Time.now}
instance << {:metric => {'a' => 10},:time => Time.now}
instance << {:metric => {'a' => 10},:time => Time.now}
instance << {:metric => {'a' => 10},:time => Time.now}
instance << {:metric => {'a' => 10},:time => Time.now}
instance << {:metric => {'a' => 10},:time => Time.now}
t = Thread.new {1.upto(10).each {instance << {:metric => {'z' => 10},:time => Time.now}}}
instance.stream(1,"asds.abcd 12 123213212332")
instance.stream(1,"\nasds.abc 12 123213212332\n")
instance.each do |line|
  p line
end
t.join
p instance

require File.expand_path("../../graphite-api",__FILE__)
buff = GraphiteAPI::Buffer.new(GraphiteAPI::Utils.default_options)
buff.stream "test.shuki.tuki 123 #{Time.now.to_i}"
buff.stream "\n"
buff.stream "mem.usage 1"
buff.stream "90 1326842563\n"
buff.stream "test.shuki.tuki 123 #{Time.now.to_i}\n"
buff.stream "lo.tov \n"
buff.stream "lo.tov 112332\n"
buff.stream "lo."
buff.stream "tov"
buff.stream "\n"
buff.stream "ken.tov 11.2332 231231321\n"
buff.stream("client1",:client1)
buff.stream("client2",:client2)
buff.stream(" 1",:client1)
buff.stream(" 2",:client2)
buff.stream(" 213232\n",:client1)
buff.stream(" 213232\n",:client2)
buff.stream("a.b 1211 121212\nc.d 1211 121212\n",:client2)
buff.stream("test.x 10 1334771088\ntest.z 10 1334771088\n",:client2)

buff.pull.each {|m| p m}
=end