# Description
**GraphiteAPI** provides two ways for interacting with **Graphite's Carbon Daemon**, the first is for Ruby applications using the **GraphiteAPI::Client**, the second is through **GraphiteAPI-Middleware** daemon, both methods implements Graphite's [plaintext protocol](http://graphite.readthedocs.org/en/1.0/feeding-carbon.html).

## Package Content
* Includes a **simple** client for ruby.
* Ships with a **GraphiteAPI-Middleware**, which is a lightweight, event-driven, aggregator daemon.
* Utilities like scheduling and caching.

## Key Features
* **Multiple Graphite Servers Support** - GraphiteAPI-Middleware supports sending aggregated data to multiple graphite servers, in a multiplex fashion, useful for large data centers and backup purposes
* **Reanimation mode** - support cases which the same keys (same timestamps as well) can be received simultaneously and asynchronously from multiple input sources, in these cases GraphiteAPI-Middleware will "reanimate" old records (records that were already sent to Graphite server), and will send the sum of the reanimated record value + the value of the record that was just received to the graphite server; this new summed record should override the key with the new value on Graphite database.
* **non-blocking I/O** ( EventMachine aware ).
* **Thread-Safe** client.

## Status
[![Gem Version](https://badge.fury.io/rb/graphite-api.svg)](https://badge.fury.io/rb/graphite-api)
[![Build Status](https://travis-ci.org/kontera-technologies/graphite-api.svg?branch=master)](https://travis-ci.org/kontera-technologies/graphite-api)
[![Test Coverage](https://codecov.io/gh/kontera-technologies/graphite-api/branch/master/graph/badge.svg)](https://codecov.io/gh/kontera-technologies/graphite-api)

## Installation
Install stable version

```
gem install graphite-api
```

## Client Usage

Creating a new UDP client

```ruby
require 'graphite-api'

options = {
  # Required: valid URI {udp,tcp}://host:port/?timeout=seconds
  graphite: "udp://graphite.example.com:2003",

  # Optional: add example.prefix to each key
  prefix: ["example","prefix"],

  # Optional: results are aggregated in 60 seconds slices ( default is 60 )
  slice: 60,

  # Optional: send to graphite every 60 seconds ( default is 0 - direct send )
  interval: 60,

  # Optional: set the max age in seconds for records reanimation ( default is 12 hours )
  cache: 4 * 60 * 60,

  # Optional: The default aggregation method for multiple reports in the same slice (default is :sum).
  # Possible options: :sum, :avg, :replace
  default_aggregation_method: :avg
}

client = GraphiteAPI.new options
```

TCP Client
```ruby
client = GraphiteAPI.new graphite: "tcp://graphite.example.com:2003"
```

TCP Client with 30 seconds timeout
```ruby
client = GraphiteAPI.new graphite: "tcp://graphite.example.com:2003?timeout=30"
```

TCP Client with custom aggregation method
```ruby
client = GraphiteAPI.new graphite: "tcp://graphite.example.com:2003", default_aggregation_method: :avg
```

Adding simple metrics
```ruby
require 'graphite-api'

client = GraphiteAPI.new( graphite: 'tcp://graphite:2003' )

client.metrics "webServer.web01.loadAvg" => 10.7
# => webServer.web01.loadAvg 10.7 time.now.to_i

client.metrics(
  "webServer.web01.loadAvg"  => 10.7,
  "webServer.web01.memUsage" => 40
)
# => webServer.web01.loadAvg  10.7 1326067060
# => webServer.web01.memUsage 40 1326067060
```

Adding metrics with timestamp
```ruby
require 'graphite-api'

client = GraphiteAPI.new( graphite: 'udp://graphite:2003' )

client.metrics({
  "webServer.web01.loadAvg"  => 10.7,
  "webServer.web01.memUsage" => 40
},Time.at(1326067060))
# => webServer.web01.loadAvg  10.7 1326067060
# => webServer.web01.memUsage 40 1326067060
```

Adding metrics with custom aggregation method
```ruby
require 'graphite-api'

client = GraphiteAPI.new( graphite: 'udp://graphite:2003' )

client.metrics({
  "webServer.web01.loadAvg"  => 10,
  "webServer.web01.memUsage" => 40
},Time.at(1326067060), :avg)
client.metrics({
  "webServer.web01.loadAvg"  => 20,
  "webServer.web01.memUsage" => 50
},Time.at(1326067060), :avg)
# => webServer.web01.loadAvg  15 1326067060
# => webServer.web01.memUsage 45 1326067060
```

Verifying connectivity
```ruby
require 'graphite-api'

client = GraphiteAPI.new graphite: 'udp://UNKNOWN-HOST:1234'
client.check!

# SocketError: udp://UNKNOWN-HOST:1234: getaddrinfo: nodename nor servname provided, or not known
```

Increment records
```ruby
require 'graphite-api'

client = GraphiteAPI.new( graphite: 'tcp://graphite:2003' )

client.increment("jobs_in_queue", "num_errors")
# => jobs_in_queue 1 Time.now.to_i
# => num_errors 1 Time.now.to_i

client.increment("jobs_in_queue", "num_errors", by: 999)
# => jobs_in_queue 999 Time.now.to_i
# => num_errors 999 Time.now.to_i

client.increment("jobs_in_queue", "num_errors", by: 20, time: Time.at(123456))
# => jobs_in_queue 20 123456
# => num_errors 20 123456

```

Built-in timers support
```ruby
require 'graphite-api'

client = GraphiteAPI.new( graphite: 'tcp://graphite:2003' )

# lets send the metric every 120 seconds
client.every(120) do |c|
  c.metrics("webServer.web01.uptime" => `uptime`.split.first.to_i)
end
```

Built-in extension for time declarations stuff, like 2.minutes, 3.hours etc...
```ruby
require 'graphite-api'
require 'graphite-api/core_ext/numeric'

client = GraphiteAPI.new( graphite: 'udp://graphite:2003' )

client.every 10.seconds do |c|
  c.metrics("webServer.web01.uptime" => `uptime`.split.first.to_i)
end

client.every 52.minutes do |c|
  c.metrics("just.fake" => 12)
end
```

Make your own custom metrics daemons, using `client#join`
```ruby
require 'graphite-api'
require 'graphite-api/core_ext/numeric'

client = GraphiteAPI.new( graphite: 'udp://graphite:2003' )

client.every 26.minutes do |c|
  c.metrics("webServer.shuki.stats" => 10)
  c.metrics("webServer.shuki.x" => 97)
  c.metrics("webServer.shuki.y" => 121)
end

client.join # wait for ever...
```

Logger
```ruby
# Provide an external logger
require 'graphite-api'
require 'logger'

GraphiteAPI::Logger.logger = ::Logger.new(STDOUT)
GraphiteAPI::Logger.logger.level = ::Logger::DEBUG

# Or use the built-in one
GraphiteAPI::Logger.init level: :debug, dev: 'logger.out' # or STDOUT | STDERR
```

## GraphiteAPI-Middleware Usage
* After installing GraphiteAPI gem, the `graphite-middleware` command should be available.

```
[root@graphite-middleware-node]# graphite-middleware --help

GraphiteAPI Middleware Server

Usage: graphite-middleware [options]
    -g, --graphite HOST:PORT         graphite host, in HOST:PORT format (can be specified multiple times)
    -p, --port PORT                  listening port (default 2003)
    -l, --log-file FILE              log file
    -L, --log-level LEVEL            log level (default warn)
    -P, --pid-file FILE              pid file (default /var/run/graphite-middleware.pid)
    -d, --daemonize                  run in background
    -i, --interval INT               report every X seconds (default 60)
    -s, --slice SECONDS              send to graphite in X seconds slices (default 60)
    -r, --reanimation HOURS          reanimate records that are younger than X hours, please see README
    -m, --aggregation-method method  The aggregation method (sum, avg or replace) for multiple reports in the same time slice (default sum)

More Info @ https://github.com/kontera-technologies/graphite-api
```

* launch **GraphiteAPI-Middleware** daemon

```
[root@graphite-middleware-node]# graphite-middleware              \
  --port 2005                                                     \
  --interval 60                                                   \
  --log-level debug                                               \
  --log-file /tmp/graphite-middleware.out                         \
  --daemonize                                                     \
  --graphite graphite-server:2003                                 \
  --graphite graphite-backup-server:2003
```

* Send metrics via **UDP/TCP sockets**

```
[root@graphite-middleware-node] telnet localhost 2005
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
example.middleware.value 10.2 1335008343
example.middleware.value2 99 1334929231
^C
[root@graphite-middleware-node]
```

* Or via **GraphtieAPI client**

```ruby
require 'graphite-api'
client = GraphiteAPI.new(:graphite => 'tcp://graphite-middleware-node:2005')
client.example.middleware.value 10.2
client.example.middleware.value2 27
client.bla.bla.value2 27
```

## Example Setup
<br/>
<img src="https://raw.github.com/kontera-technologies/graphite-api/master/examples/middleware_t1.png" align="center">

## Bugs

If you find a bug, feel free to report it @ our [issues tracker](https://github.com/kontera-technologies/graphite-api/issues) on github.

## License

It is free software, and may be redistributed under the terms specified in [LICENSE](https://github.com/kontera-technologies/graphite-api/blob/master/LICENSE).

## Warranty
This software is provided “as is” and without any express or implied warranties, including, without limitation, the implied warranties of merchantability and fitness for a particular purpose.
