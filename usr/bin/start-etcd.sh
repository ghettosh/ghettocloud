#!/usr/bin/env sh

uname -n | grep ^c0 > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "Not a managed customer hostname"
  exit 1
fi

INTERFACE_WITH_DEFAULT_GW=$(netstat -nrfinet | awk '/^default/{print $8}')
MYMAC="$(netstat -nI ${INTERFACE_WITH_DEFAULT_GW} | \                           
        grep -oE "([a-zA-Z0-9]+:[a-zA-Z0-9]+){5}")"                             
export MACADDRESS=${MYMAC}

if [[ "${USER}" == "etcd" ]]; then
  if pgrep etcd > /dev/null 2>&1; then
    pkill etcd > /dev/null 2>&1
    sleep 5
  fi
  ROADSIGN=http://ghetto.sh/roadsign.txt
  API_SERVER="$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)"
  
  MYIP=$(netstat -ni | \
    grep "^$(netstat -rnfinet | grep ^default | awk '{print $8}')" | \
    egrep -v "Link|fe80" | awk '{print $4}')
  
  if [ -z "${MYIP}" ]; then
    sendlog.pl "Could not determine IP for etcd listener"
    exit 1
  fi
  
  CUSTOMER=$(uname -n | cut -d- -f1)
  KEY=$(echo -n ${CUSTOMER} | sha1) # TODO: Make this secure.
  API_COMMAND="/checkin?discovery=${CUSTOMER}&key=${KEY}"
  
  DISCOVERY_URL=$(ftp -Vo- -r5 ${API_SERVER}/${API_COMMAND})
  
  cd /home/etcd/etcd
  ./bin/etcd -f \
    -name $(uname -n) \
    -peer-addr ${MYIP}:7001 \
    -addr ${MYIP}:4001 \
    -peer-election-timeout 2000 \
    -discovery ${DISCOVERY_URL} > /dev/null 2>&1 &
  
  sleep 10
  pgrep etcd > /dev/null 2>&1 && { sendlog.pl "started etcd"; } \
                              || { sendlog.pl "Could not etcd"; }
else
  sendlog.pl "someone other than etcd tried to run this script: $0"
fi
