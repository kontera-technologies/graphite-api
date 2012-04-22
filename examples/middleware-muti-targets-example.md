## Environment
* Graphite server running on `graphite-server:2003`
* Graphite backup server running on `graphite-backup-server:2003`
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
													--graphite graphite-server:2003 \
													--graphite graphite-backup-server:2003
```

## Client
```bash
[root@graphite-middleware-node] telnet localhost 2005
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
example.middleware.value 10.2 1335008343
example.middleware.value2 99 1334929231
^C
[root@graphite-middleware-node]
```

## Checking log
```ruby
[root@graphite-middleware-node] cat /tmp/graphite-middleware.out
 INFO -- : Server running on port 2005
 DEBUG -- : [:middleware, :connecting, "127.0.0.1:64774"]
 DEBUG -- : [:middleware, :message, "127.0.0.1:64774", "example.middleware.value 10.2 1335008343\r\n"]
 DEBUG -- : [:buffer, :add, {:metric=>{"example.middleware.value"=>"10.2"}, :time=>2012-04-21 04:39:03 -0700}]
 DEBUG -- : [:connector_group, :publish, 1, [GraphiteAPI::Connector graphite-server:2003, GraphiteAPI::Connector graphite-backup-server:2003]]
 DEBUG -- : [:connector, :puts, "graphite-server:2003", "example.middleware.value 10.2 1335008340"]
 DEBUG -- : [:connector, :puts, "graphite-backup-server:2003", "example.middleware.value 10.2 1335008340"]
 DEBUG -- : [:middleware, :message, "127.0.0.1:64774", "example.middleware.value2 99 1334929231\r\n"]
 DEBUG -- : [:buffer, :add, {:metric=>{"example.middleware.value2"=>"99"}, :time=>2012-04-20 06:40:31 -0700}]
 DEBUG -- : [:connector_group, :publish, 1, [GraphiteAPI::Connector graphite-server:2003, GraphiteAPI::Connector graphite-backup-server:2003]]
 DEBUG -- : [:connector, :puts, "graphite-server:2003", "example.middleware.value2 99.0 1334929200"]
 DEBUG -- : [:connector, :puts, "graphite-backup-server:2003", "example.middleware.value2 99.0 1334929200"]
```