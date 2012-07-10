#!/bin/sh
#
# Startup script for the westchamber proxy
#
# pidfile: ./wcproxy.pid

wcproxy=./westchamberproxy.py
[ -f $wcproxy ] || exit 0

pidfile=./wcproxy.pid

if [ -d "/tmp" ]; then
    pidfile=/tmp/wcproxy.pid
fi

if [ $(whoami) = "root" ]; then
    if [ -d "/var/run" ]; then
        pidfile=/var/run/wcproxy.pid
    fi
fi
RETVAL=0

# See how we were called.
case "$1" in
  start)
        echo "Starting wcproxy: "
         $wcproxy --pidfile $pidfile &
        ;;
  stop)
        if [ -f $pidfile ]; then
        processcheck="ps -c"
        if $processcheck `cat $pidfile` > /dev/null; then
            echo "Shutting down wcproxy: "
            kill -9 `cat $pidfile`
        fi
        RETVAL=$?
        [ $RETVAL -eq 0 ] && rm -f $pidfile
        fi
        ;;
  restart)
	$0 stop
	$0 start
	RETVAL=$?
	;;
  *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $RETVAL

