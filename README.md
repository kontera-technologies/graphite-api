# GraphiteAPI [Beta]
A Ruby API toolkit for [Graphite](http://graphite.wikidot.com/).

## Description
**GraphiteAPI** is a library written in Ruby that provides two ways for interacting with **Graphite's Carbon Daemon**, the first is for Ruby applications using the **GraphiteAPI::Client**, the second is through **GraphiteAPI-Middleware** daemon, both methods implements Graphite's [plaintext protocol](http://graphite.readthedocs.org/en/1.0/feeding-carbon.html).

## Package Content
* Includes a **simple** client for ruby.
* Ships with a **GraphiteAPI-Middleware**, which is a lightweight, event-driven, aggregator daemon.
* only one dependency (EventMachine).
* Utilities like scheduling and caching.

## Key Features
* **Multiple Graphite Servers Support** - GraphiteAPI-Middleware supports sending aggregated data to multiple graphite servers, useful for large data centers and backup purposes
* **Reanimation mode** - support cases which the same keys (same timestamps as well) can be received simultaneously and asynchronously from multiple input sources, in these cases GraphiteAPI-Middleware will "reanimate" old records (records that were already sent to Graphite server), and will send the sum of the reanimated record value + the value of the record that was just received to the graphite server; this new summed record should override the key with the new value on Graphite database.

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

## Client Usage
```ruby
  require 'graphite-api'
  require 'logger'
  
  # Turn on the logging ( optional )
  GraphiteAPI::Logger.logger = ::Logger.new(STDOUT)
  GraphiteAPI::Logger.logger.level = ::Logger::DEBUG
  
  # Setup client
  client = GraphiteAPI::Client.new(  
   :graphite => "graphite.example.com:2003",
   :prefix   => ["example","prefix"], # add example.prefix to each key
   :slice    => 60.seconds            # results are aggregated in 60 seconds slices
   :interval => 60.seconds            # send to graphite every 60 seconds
  )
  
  # Simple
  client.webServer.web01.loadAvg 10.7 
  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.to_i
  
  # "Same Same But Different" ( http://en.wikipedia.org/wiki/Tinglish )
  client.metrics "webServer.web01.loadAvg" => 10.7
  # => example.prefix.webServer.web01.loadAvg 10.7 time.now.to_i
  
  # With event time
  client.webServer.web01.blaBlaBla(29.1, Time.at(9999999999))
  # => example.prefix.webServer.web01.blaBlaBla 29.1 9999999999
  
  # Multiple with event time
  client.metrics({
    "webServer.web01.loadAvg"  => 10.7,
    "webServer.web01.memUsage" => 40
  },Time.at(1326067060))
  # => example.prefix.webServer.web01.loadAvg  10.7 1326067060
  # => example.prefix.webServer.web01.memUsage 40 1326067060
  
  # Timers
  client.every 10.seconds do |c|
    c.webServer.web01.uptime `uptime`.split.first.to_i
    # => example.prefix.webServer.web01.uptime 40 1326067060
  end
  
  client.every 52.minutes do |c|
    c.abcd.efghi.jklmnop.qrst 12 
    # => example.prefix.abcd.efghi.jklmnop.qrst 12 1326067060
  end
  
  client.join # wait...
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

* Send metrics via **GraphtieAPI client**

```ruby
require 'graphite-api'
client = GraphiteAPI::Client.new(:graphite => graphite-middleware-node)
client.example.middleware.value 10.2 
client.example.middleware.value2 27
client.bla.bla.value2 27
```

> more examples can be found [here](https://github.com/kontera-technologies/graphite-api/tree/master/examples).


## Recommended Topologies
<br/>

<img src="https://raw.github.com/kontera-technologies/graphite-api/master/examples/graphite-middleware-star.jpg" align="center">

<hr/>
<br/>

<img src="https://raw.github.com/kontera-technologies/graphite-api/master/examples/graphite-middleware-mesh.jpg" align="center">

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
