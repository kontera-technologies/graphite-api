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
=end