#!/usr/bin/env bash

PIDFILE=/data/serve/ghettoapi/logs/httpd-ghettoapi.pid
HTTPDCONF=/data/serve/ghettoapi/conf/ghettoapi-httpd.conf

printf "INFO: Starting or restarting the webserver"
if [ -r ${PIDFILE} ]; then
  kill `cat ${PIDFILE}` > /dev/null 2>&1
fi

httpd -u \
      -4 \
      -f ${HTTPDCONF} > /dev/null 2>&1

for i in {1..3}; do printf "."; sleep 1; done

echo "New PID: $(cat ${PIDFILE})"
