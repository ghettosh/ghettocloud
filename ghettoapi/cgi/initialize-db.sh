#!/usr/bin/env bash

#
# Initialize the database
#

function usage(){
    echo "Usage: $0 <db file>"
    exit 1
}

SQLITE3=`which sqlite3 2>/dev/null`
SQLITE3=${SQLITE3:?FATAL: no sqlite3 found}

DBFILE=$1
DBFILE=${DBFILE:?$(usage)}

DBUSER="www"     # drop privs to www
DBGROUP="daemon" # drop privs to daemon

if [[ ! ${DBFILE} =~ .*.db ]]; then DBFILE=${DBFILE}.db; fi

if [[ ! -r ${DBFILE} ]]; then 
    echo "==> Database file: ${DBFILE} not found, creating one"
else
    echo "==> Database file ${DBFILE} found, backing it up and reinitializing"
    BACKUP=$DBFILE-backup-$(date +%s)
    mv $DBFILE $BACKUP
    echo "==> moved $DBFILE to $BACKUP"
fi

echo "==> reinitializing database at ${DBFILE}"

${SQLITE3} ${DBFILE} "CREATE TABLE vms (id INTEGER PRIMARY KEY,
                        realname TEXT,
                        hostname TEXT,
                        state TEXT,
                        ip TEXT,
                        macaddr TEXT, 
                        rootpw TEXT, 
                        hypervisor TEXT,
                        creationdate TEXT);"

${SQLITE3} ${DBFILE} "CREATE TABLE messages (id INTEGER PRIMARY KEY,
                  message TEXT, 
                  date TEXT, 
                  macaddr TEXT);"

${SQLITE3} ${DBFILE} "CREATE TABLE discovery (id INTEGER PRIMARY KEY,
                  token TEXT,
                  _key TEXT,
                  customer TEXT);"

echo "==> initialized db"
echo "==> database schema:"
${SQLITE3} ${DBFILE} ".schema"
echo "==> setting permissions on dbfile"
chown ${DBUSER}:${DBGROUP} ${DBFILE}
echo "==> done"
