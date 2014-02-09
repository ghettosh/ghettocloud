#!/usr/bin/env sh

MYNAME="$(uname -n | cut -d. -f1)"
MYUNAME="$(uname -a | tr ' ' ',')"
MYIPS=
ROADSIGN=http://ghetto.sh/roadsign.txt # Location of a file that tells this 
                                       # script where the API head is.

# populate a list of IPs, in case the VM has multiple interfaces
# We don't have array capabilities here because ksh.
#for IP in $(ifconfig -a | awk '/inet /{print $2}'); do
#    if [[ $IP == "127.0.0.1" ]]; then
#        continue
#    else
#        MYIPS="${MYIPS} $IP"
#    fi
#done
MYIPS=$(netstat -ni | \
    egrep -v "<Link>|::|127.0.0.1|^Name" | \
    awk '{print $1, $4}' | tr '\n' ',' | sed -e 's/,$//g;s/ /:/g';)

if [[ -z ${MYIPS} ]]; then
    MYIPS=ERROR
else
    MYIPS="$(echo $MYIPS | tr ' ' '+')"
fi

if [ -z ${MYNAME} ]; then
    MYNAME=ERROR
fi

if [ -z ${MYUNAME} ]; then
    MYUNAME=ERROR
fi

API_SERVER="$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)"
if [[ ! -z ${API_SERVER} ]]; then
    API_COMMAND="checkin/${MYNAME}/$(date +%s)/${MYIPS}/${MYUNAME}"
    URL="http://${API_SERVER}/${API_COMMAND}"
    echo "hitting $URL"
    ftp -Vo- -r 2 ${URL} 2>/dev/null
fi
