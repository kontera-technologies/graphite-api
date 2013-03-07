# GraphiteAPI
A Ruby API toolkit for [Graphite](http://graphite.wikidot.com/).

## Description
**GraphiteAPI** provides two ways for interacting with **Graphite's Carbon Daemon**, the first is for Ruby applications using the **GraphiteAPI::Client**, the second is through **GraphiteAPI-Middleware** daemon, both methods implements Graphite's [plaintext protocol](http://graphite.readthedocs.org/en/1.0/feeding-carbon.html).

## Package Content
* Includes a **simple** client for ruby.
* Ships with a **GraphiteAPI-Middleware**, which is a lightweight, event-driven, aggregator daemon.
* Only one gem dependency ( EventMachine ).
* Utilities like scheduling and caching.

## Key Features
* **Multiple Graphite Servers Support** - GraphiteAPI-Middleware supports sending aggregated data to multiple graphite servers, in a multiplex fashion, useful for large data centers and backup purposes
* **Reanimation mode** - support cases which the same keys (same timestamps as well) can be received simultaneously and asynchronously from multiple input sources, in these cases GraphiteAPI-Middleware will "reanimate" old records (records that were already sent to Graphite server), and will send the sum of the reanimated record value + the value of the record that was just received to the graphite server; this new summed record should override the key with the new value on Graphite database.
* **non-blocking I/O** ( EventMachine aware ).
* **Thread-Safe** client.

## Installation
Install stable version

```
gem install graphite-api
```

Install the latest from github

```
git clone git://github.com/kontera-technologies/graphite-api.git
cd graphite-api
rake install
```
<table><tr>
    <td> Current gem version </td>
    <td><img src=https://fury-badge.herokuapp.com/rb/graphite-api.png></td>
</tr></table>

## Client Usage
Creating a new client instance

```ruby
require 'graphite-api'

GraphiteAPI::Client.new(
  graphite: "graphite.example.com:2003", # not optional
  prefix: ["example","prefix"], # add example.prefix to each key
  slice: 60 # results are aggregated in 60 seconds slices
  interval: 60 # send to graphite every 60 seconds
  cache: 4 * 60 * 60 # set the max age in seconds for records reanimation
)
```

Adding simple metrics
```ruby
require 'graphite-api'

client = GraphiteAPI::Client.new( graphite: 'graphite:2003' )

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

client = GraphiteAPI::Client.new( graphite: 'graphite:2003' )

client.metrics({
  "webServer.web01.loadAvg"  => 10.7,
  "webServer.web01.memUsage" => 40
},Time.at(1326067060))
# => webServer.web01.loadAvg  10.7 1326067060
# => webServer.web01.memUsage 40 1326067060
```

Some DSL sweetness
```ruby
require 'graphite-api'

client = GraphiteAPI::Client.new( graphite: 'graphite:2003' )

client.webServer.web01.loadAvg 10.7 
# => webServer.web01.loadAvg 10.7 time.now.to_i

client.webServer.web01.blaBlaBla(29.1, Time.at(9999999999))
# => webServer.web01.blaBlaBla 29.1 9999999999
```

Built-in timers support
```ruby
require 'graphite-api'

client = GraphiteAPI::Client.new( graphite: 'graphite:2003' )

# lets send the metric every 120 seconds
client.every(120) do |c|
  c.webServer.web01.uptime `uptime`.split.first.to_i
end
```

Built-in extension for time declarations stuff, like 2.minutes, 3.hours etc...
```ruby
require 'graphite-api'
require 'graphite-api/core_ext/numeric'

client = GraphiteAPI::Client.new( graphite: 'graphite:2003' )

client.every 10.seconds do |c|
  c.webServer.web01.uptime `uptime`.split.first.to_i
end

client.every 52.minutes do |c|
  c.just.fake 12
end
```

Make your own custom metrics daemons, using `client#join`
```ruby
require 'graphite-api'
require 'graphite-api/core_ext/numeric'

client = GraphiteAPI::Client.new( graphite: 'graphite:2003' )

client.every 26.minutes do |c|
  c.webServer.shuki.stats 10
  c.webServer.shuki.x 97
  c.webServer.shuki.y 121
end

client.join # wait for ever...
```

Logging support

```ruby
# Provide an external logger
require 'graphite-api'
require 'logger'

GraphiteAPI::Logger.logger = ::Logger.new(STDOUT)
GraphiteAPI::Logger.logger.level = ::Logger::DEBUG

# Or use the built-in one
GraphiteAPI::Logger.init(
  :level => :debug,
  :std   => 'logger.out' # or STDOUT | STDERR
)
```

> more examples can be found [here](https://github.com/kontera-technologies/graphite-api/tree/master/examples).

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
client = GraphiteAPI::Client.new(:graphite => 'graphite-middleware-node:2005')
client.example.middleware.value 10.2 
client.example.middleware.value2 27
client.bla.bla.value2 27
```

> more examples can be found [here](https://github.com/kontera-technologies/graphite-api/tree/master/examples).


### Recommended Topology
<br/>
<img src="https://raw.github.com/kontera-technologies/graphite-api/thread-safe/examples/middleware_t1.png" align="center">
<hr/>

## TODO:
* Documentation
* Use Redis
* Multiple backends via client as well

## Bugs

If you find a bug, feel free to report it @ our [issues tracker](https://github.com/kontera-technologies/graphite-api/issues) on github.

## License

It is free software, and may be redistributed under the terms specified in [LICENSE](https://github.com/kontera-technologies/graphite-api/blob/master/LICENSE).

## Warranty
This software is provided “as is” and without any express or implied warranties, including, without limitation, the implied warranties of merchantability and fitness for a particular purpose.
