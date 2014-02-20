#!/usr/bin/env bash
PIDFILE=/data/serve/ghettoapi/logs/httpd-ghettoapi.pid
HTTPDCONF=/data/serve/ghettoapi/conf/ghettoapi-httpd.conf

if [ -r ${PIDFILE} ]; then
  kill `cat ${PIDFILE}` > /dev/null 2>&1
fi

httpd -u \
      -4 \
      -f ${HTTPDCONF}

echo "INFO: New PID: $(cat ${PIDFILE})"
ps auxww | grep httpd | grep -v grep
