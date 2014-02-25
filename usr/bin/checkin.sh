#!/usr/bin/env sh


PKGMIRROR="http://openbsd.mirrorcatalogs.com"
PATHTOROOTKEY="/static/authorized_keys"
MYNAME="$(uname -n | cut -d. -f1)"
MYUNAME="$(uname -a | tr ' ' ',')"
INTERFACE_WITH_DEFAULT_GW=$(netstat -nrfinet | awk '/^default/{print $8}')
MYIPS=
ROADSIGN=http://ghetto.sh/roadsign.txt # Location of a file that tells this 
                                       # script where the API head is.
STATE="running"   # maybe in future we change the state, for now we'll let
                  # this script send 'running' to the api

MYIP="$(netstat -nI ${INTERFACE_WITH_DEFAULT_GW} | \
        grep -oE "[0-9]+\.([0-9]+\.[0-9]+){2}")"

MYMAC="$(netstat -nI ${INTERFACE_WITH_DEFAULT_GW} | \
        grep -oE "([a-zA-Z0-9]+:[a-zA-Z0-9]+){5}")"

UPTIME="$(uptime | cut -d, -f1 | sed -e 's/^[ \t]*//g;s/  / /g')"
LOADAVG="$(uptime | cut -d, -f4,5,6 | sed -e 's/^[ \t]*//g')"

if [[ -z "${MYIP}" ]]; then
    MYIP=ERROR
fi

if [[ -z "${MYMAC}" ]]; then
    MYMAC=ERROR
fi

if [ -z "${MYNAME}" ]; then
    MYNAME=ERROR
fi

if [ -z "${UPTIME}" ]; then
    UPTIME=ERROR
fi

if [ -z "${LOADAVG}" ]; then
    LOADAVG=ERROR
fi

API_SERVER="$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)"
# Check for an update to the siteNN.tgz; be very careful!!!
if [ ! -z ${API_SERVER} ]; then
  if ! grep 'export PKG_PATH' /root/.profile > /dev/null 2>&1; then
    if [ $(uname -r) == "5.5" ]; then
      RELEASE=snapshots
    else
      RELEASE=`uname -r`
    fi
    PKG_PATH="${PKGMIRROR}/${RELEASE}/packages/`uname -m`"
    echo "export PKG_PATH=${PKG_PATH}" >> /root/.profile
  fi
  MYSUM=$(md5 $0 | cut -d= -f2 | tr -d ' ')
  REMOTESUM

  # We didn't exit from the above routines, so we'll check in.
  API_COMMAND="checkin?"
  API_COMMAND="${API_COMMAND}state=${STATE}-${MYSUM}&"
  API_COMMAND="${API_COMMAND}ip=${MYIP}&"
  API_COMMAND="${API_COMMAND}macaddr=${MYMAC}&"
  API_COMMAND="${API_COMMAND}hostname=$(uname -n)"
  URL="${API_SERVER}/${API_COMMAND}"
  echo "hitting $URL"
  ftp -Vo- -r 2 ${URL} 2>/dev/null
fi
