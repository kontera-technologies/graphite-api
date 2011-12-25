# Lets start new graphite api middleware
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
# + log file @ /tmp/graphite-middleware.log
# + pid file @ /tmp/graphite-middleware.pid
# + Run in the background
# + Report the Graphite server every 60 seconds
%x(
  graphite-middleware --port 2004 \
  --graphite graphite.kontera.com \
  --log-file /tmp/graphite-middleware.log \
  --log-level debug \
  --pid-file /tmp/graphite-middleware.pid \
  --interval 60 \
  --daemonize
)