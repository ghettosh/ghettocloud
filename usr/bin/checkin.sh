#!/usr/bin/env sh

MYNAME="$(uname -n | cut -d. -f1)"
MYUNAME="$(uname -a | tr ' ' ',')"
MYIPS=
ROADSIGN=http://ghetto.sh/roadsign.txt

# populate MYIPS
for IP in $(ifconfig -a | awk '/inet /{print $2}'); do
    if [[ $IP == "127.0.0.1" ]]; then
        continue
    else
        MYIPS="${MYIPS} $IP"
    fi
done

if [[ -z ${MYIPS} ]]; then
    MYIPS=NULL
else
    MYIPS="$(echo $MYIPS | tr ' ' '+')"
fi

if [ -z ${MYNAME} ]; then
    MYNAME=NULL
fi

if [ -z ${MYUNAME} ]; then
    MYUNAME=NULL
fi
URL="http://$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)/name=${MYNAME}&ips=${MYIPS}&uname=${MYUNAME}"
echo "hitting $URL"
ftp -Vo- -r 2 ${URL}
