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
#MYIPS=$(netstat -ni | \
#    egrep -v "<Link>|::|127.0.0.1|^Name" | \
#    awk '{print $1, $4}' | tr '\n' ',' | sed -e 's/,$//g;s/ /:/g';)

MYIPS=$(netstat -ni | \
        egrep -v "::|127.0.0.1|^Name|lo0|enc0" | \
        awk '{print $1, $4}' | \
        tr '\n' ',' | \
        sed -e 's/,$//g;s/ /:/g';)

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

# Check for an update to the site55.tgz; be very careful!!!
if [[ ! -z ${API_SERVER} ]]; then
    MYSUM=$(md5 $0 | cut -d= -f2 | tr -d ' ')
    REMOTESUM=$(ftp -Vo- -r 5 ${API_SERVER}/siteupdate 2>/dev/null | tr -d ' ')
    if [ -z ${REMOTESUM} ]; then
        echo "FATAL: Could not get remote sum. Not going to check in"
        exit 1
    else
        if [[ ${REMOTESUM} != ${MYSUM} ]] ;then
            UPDATE_REQUIRED=1
            cd /tmp
            ftp -V ${API_SERVER}/site-current.tgz 2>/dev/null
            if [ -f /tmp/site-current.tgz ]; then
                tar -zxvf /tmp/site-current.tgz -C /
            else
                echo "FATAL: File was not downloaded properly"
                exit 1
            fi
        fi
    fi

    # We didn't exit from the above routines, so we'll check in.
    API_COMMAND="checkin/${MYNAME}/$(date +%s)/${MYIPS}/${MYUNAME}"
    URL="http://${API_SERVER}/${API_COMMAND}"
    echo "hitting $URL"
    ftp -Vo- -r 2 ${URL} 2>/dev/null
fi
