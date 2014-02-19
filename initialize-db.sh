#!/usr/bin/env bash

function usage(){
    echo "Usage: $0 <db file>"
    exit 1
}

SQLITE3=`which sqlite3 2>/dev/null`
SQLITE3=${SQLITE3:?FATAL: no sqlite3 found}

DBFILE=$1
DBFILE=${DBFILE:?$(usage)}

if [[ ! ${DBFILE} =~ *.db ]]; then DBFILE=${DBFILE}.db; fi

if [[ ! -r ${DBFILE} ]]; then 
    echo "==> Database file: ${DBFILE} not found, creating one"
else
    echo "==> Database file ${DBFILE} found, backing it up and reinitializing"
    BACKUP=$DBFILE-backup-$(date +%s)
    mv $DBFILE $BACKUP
    echo "==> moved $DBFILE to $BACKUP"
fi

echo "==> reinitializing database at ${DBFILE}"

${SQLITE3} ${DBFILE} "create table vms (id INTEGER PRIMARY KEY,
                  hostname TEXT, 
                  realname TEXT,
                  macaddr TEXT, 
                  rootpw TEXT, 
                  hypervisor TEXT,
                  creationdate TEXT)"

echo "==> initialized db"
echo "==> database schema:"
${SQLITE3} ${DBFILE} ".schema"
echo "==> done"
