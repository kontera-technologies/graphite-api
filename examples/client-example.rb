require "graphite-api"

# Setting up client
client = GraphiteAPI::Client.new(
  :graphite => "graphite.example.com:2003",   # Graphite sever (can even be pointed to GraphiteAPI middleware instance)
  :prefix => ["kontera","prefix","test"],     # Prefix, will add kontera.prefix.test to each key
  :interval => 60,                            # Send to Graphite every X seconds, default is 60
)

# Simple one
client.add_metrics("shuki.tuki" => 10.7)    # will send kontera.prefix.test.shuki.tuki 10.7 11212312321

# Multiple metrics
client.add_metrics("shuki.tuki" => 10.7,"moshe.shlomo" => 22.9)

# Every 1 sec
client.every(1) do
  client.add_metrics("one_seconds#{rand 10}" => 10)  # kontera.prefix.test.one_seconds 20.2 12321231312
end

# Every 5 sec
client.every(5) do
  client.add_metrics("five_seconds" => 10) # kontera.prefix.test.five_seconds 20.2 12321231312
end

client.join