# GraphiteAPI [Beta]
A Ruby API toolkit for [Graphite](http://graphite.wikidot.com/).

## Description
Graphite client and utilities for ruby

* **Simple** client for ruby.
* Ships with a **GraphiteAPI-Middleware**, which is a lightweight, event-driven, aggregator daemon.
* only one dependency (EventMachine).
* Utilities like scheduling and caching.

## Features
* Multiple Graphite Servers Support - GraphiteAPI-Middleware supports sending aggregated data to multiple graphite servers, useful for large data centers and backup purposes
* Reanimation mode - support cases which the same keys (same timestamps as well) can be received simultaneously and asynchronously from multiple input sources, in these cases GraphiteAPI-Middleware will "reanimate" old records (records that were already sent to Graphite server), and will send the sum of the reanimated record value + the value of the record that was just received to the graphite server; this new summed record should override the key with the new value on Graphite database.

## Client Usage
```ruby
 	require 'graphite-api'

 	client = GraphiteAPI::Client.new(
	 :graphite => "graphite.example.com:2003",
 	 :prefix => ["example","prefix"], # add example.prefix to each key
 	 :interval => 60                  # send to graphite every 60 seconds
 	)
    
 	# Simple:
 	client.metrics("webServer.web01.loadAvg" => 10.7)
 	# => example.prefix.webServer.web01.loadAvg 10.7 time.now.stamp
	
 	# Multiple with time:
 	client.metrics({
 		"webServer.web01.loadAvg" => 10.7,
 		"webServer.web01.memUsage" => 40
 	},Time.at(1326067060))
 	# => example.prefix.webServer.web01.loadAvg  10.7 1326067060
 	# => example.prefix.webServer.web01.memUsage 40 1326067060
 	
 	# Every 10 sec
 	client.every(10) do
 	  client.metrics("webServer.web01.uptime" => `uptime`.split.first.to_i) 
 	end
	
 	client.join # wait...
```	
## GraphiteAPI-Middleware Usage

```
[root@someplace]# graphite-middleware --help

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
