#!/bin/sh

#
# Use this to stop/start the webserver
#

PIDFILE=/var/tmp/httpd-ghettoapi.pid
RUNLOG=/var/tmp/ghettoapi-run.log
HTTPDCONF=/data/serve/ghettoapi/conf/ghettoapi-httpd.conf

echo "INFO: Starting or restarting the webserver(log:${RUNLOG})..."
if [ -e ${PIDFILE} ]; then
  kill `cat ${PIDFILE}` > /dev/null 2>&1
fi

/usr/sbin/httpd -u \
                -4 \
                -f ${HTTPDCONF} 2>&1 > ${RUNLOG}

sleep 3 && echo "INFO: New PID: $(cat ${PIDFILE})"
