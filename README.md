# GraphiteAPI

A Ruby API tool kit for [Graphite](http://graphite.wikidot.com/):

* Graphite ruby client.
* Graphite middleware server, a lightweight, event-driven, aggregator daemon.

## Client Usage
```ruby
 	require 'graphite-api'

 	client = GraphiteAPI::Client.new("graphite.example.com",
 	 :port => 2003,
 	 :prefix => ["example","prefix"], # add example.prefix to each key
 	 :interval => 60                  # send to graphite every 60 seconds
 	)
    
 	# Simple:
 	client.add_metrics("webServer.web01.loadAvg" => 10.7)
 	# => example.prefix.webServer.web01.loadAvg 10.7 time.now.stamp
	
 	# Multiple with time:
 	client.add_metrics({
 		"webServer.web01.loadAvg" => 10.7,
 		"webServer.web01.memUsage" => 40
 	},Time.at(1326067060))
 	# => example.prefix.webServer.web01.loadAvg  10.7 1326067060
 	# => example.prefix.webServer.web01.memUsage 40 1326067060
 	
 	# Every 10 sec
 	client.every(10) do
 	  client.add_metrics("webServer.web01.uptime" => `uptime`.split.first.to_i) 
 	end
	
 	client.join # wait...
```	
## Middleware Usage

`graphite-middleware --help`

```
Graphite Middleware Server

Usage: graphite-middleware [options]
    -g, --graphite HOST              graphite host
    -p, --port PORT                  listening port (default 2003)
    -l, --log-file FILE              log file
    -L, --log-level LEVEL            log level (default warn)
    -P, --pid-file FILE              pid file (default /var/run/graphite-middleware.pid)
    -d, --daemonize                  run in background
    -i, --interval INT               report every X seconds (default 60)
    -s, --slice SECONDS              send to graphite in X seconds slices (default is 60)
    -c, --cache HOURS                cache expiration time in hours (default is 12 hours)
```

## Installation
install the latest from github

```
git clone git://github.com/kontera-technologies/graphite-api.git
cd graphite-api
rake install
```

## Bugs

If you find a bug, feel free to report it @ our [issues tracker](https://github.com/kontera-technologies/graphite-api/issues) on github.

## License

It is free software, and may be redistributed under the terms specified in [LICENSE](https://github.com/kontera-technologies/graphite-api/blob/master/LICENSE).

## Warranty
This software is provided “as is” and without any express or implied warranties, including, without limitation, the implied warranties of merchantability and fitness for a particular purpose.
