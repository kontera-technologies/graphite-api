## Environment
* Graphite server running on `graphite-server:2003`
* GraphiteAPI-Middleware running on `graphite-middleware-node:2005`

## Starting GraphiteAPI-Middlware
```bash
[root@graphite-middleware-node] graphite-middleware --help
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
 
[root@graphite-middleware-node] graphite-middleware --port 2005 \
 													--interval 5 \
 													--log-level debug \
													--log-file /tmp/graphite-middleware.out \
													--daemonize \
													--reanimation 2 \
													--graphite graphite-server:2003
```

## Client
Sending the same record `example.value1 10 1335101880` twice in ten minutes interval

```bash
[root@graphite-middleware-node] telnet localhost 2005
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
example.value1 10 1335101880
example.value1 10 1335101880 # AFTER 10 MINUTES
^C
[root@graphite-middleware-node]
```

## Flow
```ruby
[root@graphite-middleware-node] cat /tmp/graphite-middleware.out
 INFO -- : Server running on port 2005
 DEBUG -- : [:middleware, :connecting, "localhost:65364"]
 DEBUG -- : [:middleware, :message, "localhost:65364", "example.value1 10 1335101880\r\n"]
 DEBUG -- : [:buffer, :add, {:metric=>{"example.value1"=>"10"}, :time=>2012-04-22 06:38:00 -0700}]
 DEBUG -- : [:connector_group, :publish, 1, [GraphiteAPI::Connector graphite-server:2003]]
 DEBUG -- : [:connector, :puts, "graphite-server:2003", "example.value1 10.0 1335101880"]
 DEBUG -- : [:middleware, :message, "localhost:65364", "example.value1 10 1335101880\r\n"]
 DEBUG -- : [:buffer, :add, {:metric=>{"example.value1"=>"10"}, :time=>2012-04-22 06:38:00 -0700}]
 DEBUG -- : [:connector_group, :publish, 1, [GraphiteAPI::Connector graphite-server:2003]]
 DEBUG -- : [:connector, :puts, "graphite-server:2003", "example.value1 20.0 1335101880"] # <= Resend with value of 20 (10 + 10)
```

## Same flow w/o reanimation
```ruby
 INFO -- : Server running on port 2005
 DEBUG -- : [:middleware, :connecting, "localhost:65364"]
 DEBUG -- : [:middleware, :message, "localhost:65364", "example.value1 10 1335101880\r\n"]
 DEBUG -- : [:buffer, :add, {:metric=>{"example.value1"=>"10"}, :time=>2012-04-22 06:38:00 -0700}]
 DEBUG -- : [:connector_group, :publish, 1, [GraphiteAPI::Connector graphite-server:2003]]
 DEBUG -- : [:connector, :puts, "graphite-server:2003", "example.value1 10.0 1335101880"]
 DEBUG -- : [:middleware, :message, "localhost:65364", "example.value1 10 1335101880\r\n"]
 DEBUG -- : [:buffer, :add, {:metric=>{"example.value1"=>"10"}, :time=>2012-04-22 06:38:00 -0700}]
 DEBUG -- : [:connector_group, :publish, 1, [GraphiteAPI::Connector graphite-server:2003]]
 DEBUG -- : [:connector, :puts, "graphite-server:2003", "example.value1 10.0 1335101880"] # <= Resend with value of 10
```
