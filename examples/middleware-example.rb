require 'graphite-api'
#
# eran ~/github/graphite-api/examples [git::master]  graphite-middleware --help
#
# Graphite Middleware Server
#
# Usage: graphite-middleware [options]
#    -p, --port PORT                  listening port (default 2003)
#    -g, --graphite HOST              graphite host
#    -l, --log-file FILE              log file
#    -L, --log-level LEVEL            log level (default warn)
#    -P, --pid-file FILE              pid file (default /var/run/graphite-middleware.pid)
#    -d, --daemonize                  run in background
#    -i, --interval INT               report every X seconds
#
# Start the server
# + listing on port 2004
# + graphite server @ graphite.kontera.com
# + log level debug
# + pid file @ /tmp/graphite-middleware.pid
# + Run in the foreground
# + Report the Graphite server every 10 seconds

pid = Process.spawn("graphite-middleware --port 2004 \
  --graphite graphite.kontera.com \
  --log-level debug \
  --pid-file /tmp/graphite-middleware.pid \
  --interval 10")

# Daemon is running, lets start the client
client = GraphiteAPI::Client.new("127.0.0.1", # middleware running localy
  :port => 2004,                              # middleware running port
  :interval => 1,                             # send to middleware every 1 seconds
  :aggregate => false                         # No need to aggregate data, middleware will do it for us
)

1.upto(100) do
  client.add_metrics("shuki#{rand(10)}" => 0.1)
  sleep 0.001
end

sleep 20;`kill -9 #{pid}`

# Should print
# I, [2011-12-25T17:07:55.150748 #35300]  INFO -- : Server running on port 2004
# D, [2011-12-25T17:07:56.050979 #35300] DEBUG -- : Client connecting
# D, [2011-12-25T17:08:05.241252 #35300] DEBUG -- : Sending 100 records to graphite (@graphite.kontera.com:2003)
# D, [2011-12-25T17:08:05.243163 #35300] DEBUG -- : After Aggregation 10 records (reduced 90)
#
#