#!/usr/bin/env sh

# ------
# moving these to cdist
# ------
# function ensure_package {
#     PKG=$1
#     if ! pkg_info | grep "^${PKG}" > /dev/null 2>&1; then
#         . /root/.profile && pkg_add -r ${PKG}
#     fi
# }
# PKGMIRROR="http://openbsd.mirrorcatalogs.com"
# PATHTOROOTKEY="/static/authorized_keys"

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

export MACADDR=$MYMAC # for sendmsg.pl

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
  # ------
  # moving these to cdist
  # ------
  # if ! grep 'export PKG_PATH' /root/.profile > /dev/null 2>&1; then
  #   if [ $(uname -r) == "5.5" ]; then
  #     RELEASE=snapshots
  #   else
  #     RELEASE=`uname -r`
  #   fi
  #   PKG_PATH="${PKGMIRROR}/${RELEASE}/packages/`uname -m`"
  #   echo "export PKG_PATH=${PKG_PATH}" >> /root/.profile
  # fi
  MYSUM=$(md5 $0 | cut -d= -f2 | tr -d ' ')
  URL="${API_SERVER}/checkin?update=$(uname -r)&myver=$(md5 $0 | cut -d= -f2 | tr -d ' ')"
  REMOTESUM=$(ftp -Vo- ${URL})
  echo "${REMOTESUM}" | grep 'update_required' > /dev/null 2>&1
  if [ $? -eq 0 ];then
    echo "INFO: updating"
    TARGETFILE="$(echo $REMOTESUM | grep -oE "htt(p|ps)://.*.tgz")"
    echo "INFO: Getting $TARGETFILE"
    RELEASE=$(uname -r | tr -d '.')
    cd /tmp
    ftp -V ${TARGETFILE} 2>/dev/null    
    if [ -f /tmp/site${RELEASE}.tgz ]; then                              
      tar -zxvf /tmp/site${RELEASE}.tgz -C / && sendlog.pl "updated site file"
    else                                                                 
      echo "FATAL: File was not downloaded properly"                   
      sendlog.pl "failed to update site file"
      exit 1                                                           
    fi                                                                   
  fi
  # ------
  # moving these to cdist
  # ------
  # ensure_package "bash"
  # ensure_package "python-2.7.6p0"

  # We didn't exit from the above routines, so we'll check in.
  API_COMMAND="checkin?"
  API_COMMAND="${API_COMMAND}state=${STATE}&"
  # API_COMMAND="${API_COMMAND}date=$(date +%s)&"
  # API_COMMAND="${API_COMMAND}uptime=${UPTIME}&"
  # API_COMMAND="${API_COMMAND}loadavg=${LOADAVG}&"
  API_COMMAND="${API_COMMAND}ip=${MYIP}&"
  API_COMMAND="${API_COMMAND}macaddr=${MYMAC}&"
  API_COMMAND="${API_COMMAND}hostname=$(uname -n)"
  URL="${API_SERVER}/${API_COMMAND}"
  echo "hitting $URL"
  ftp -Vo- -r 2 ${URL} 2>/dev/null
fi

sendlog.pl "checkin run ended"
