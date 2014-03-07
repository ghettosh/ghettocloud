#!/usr/bin/env bash

# 
# This script reruns a cdist catalog on all existing hypervisors.
#

CDIST_DIR=/data/cdist/
CDIST_BIN=${CDIST_DIR}/bin/cdist
DBFILE=/data/serve/ghettoapi/cgi/ghetto.db
SQLITE3=`which sqlite3`
SQL="SELECT ip FROM vms where hostname like 'c03%';"

for VM in $( ${SQLITE3} ${DBFILE} "${SQL}" ); do
  ${CDIST_BIN} -v config $VM &
done

wait
