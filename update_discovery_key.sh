#!/usr/bin/env bash

DISCOVERY_URL=https://discovery.etcd.io/new
DBFILE=/data/serve/ghettoapi/cgi/ghetto.db
SQLITE3=`which sqlite3`

CUSTOMER=${1:?$(tput setf 4)please specify a customer$(tput sgr0)}

RCOUNT=$( ${SQLITE3} ${DBFILE} \
  "SELECT count(*) FROM discovery WHERE customer='${CUSTOMER}';" )


if [[ $RCOUNT -eq 1 ]]; then

  DISCOVERY_TKN=$(ftp -Vo- ${DISCOVERY_URL})
  KEY=$(echo -n ${CUSTOMER} | sha1)

  if [[ -z "${DISCOVERY_TKN}" ]];then
    echo "FATAL: Tried to get a url from ${DISCOVERY_URL} but couldn't"
    echo "FATAL: Cannot continue"
    exit 1
  fi

  echo "INFO: Updating record -> ${DISCOVERY_TKN} : ${KEY}"
  ${SQLITE3} ${DBFILE} \
    "UPDATE discovery 
    SET token='${DISCOVERY_TKN}', _key=${KEY}
    WHERE customer='${CUSTOMER}';" && \
  { echo "INFO: Successfully updated DB"; } || \
  { echo "FATAL: Failed to update DB"; exit 2; }

elif [[ $RCOUNT -gt 1 ]]; then
  echo "ERROR: Something is wrong, the customer has more than one record here"
  exit 1
else
  echo "INFO: Creating record for customer"
  ${SQLITE3} ${DBFILE} \
    " INSERT INTO discovery (token,_key,customer) 
      VALUES ('${DISCOVERY_TKN}','${KEY}','${CUSTOMER}')"
fi
