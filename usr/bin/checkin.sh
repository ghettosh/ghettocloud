#!/usr/bin/env sh

function ensure_package {
    PKG=$1
    if ! pkg_info -Qa | grep ${PKG} > /dev/null 2>&1; then
        . /root/.profile && pkg_add -r ${PKG}
    fi
}

MYNAME="$(uname -n | cut -d. -f1)"
MYUNAME="$(uname -a | tr ' ' ',')"
MYIPS=
ROADSIGN=http://ghetto.sh/roadsign.txt # Location of a file that tells this 
                                       # script where the API head is.

if [ ! -f /root/.ssh/authorized_keys ]; then
    mkdir -p /root/.ssh > /dev/null 2>&1
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5JWrV003FzR+5B4kOY3csxgtMHqX4YU8Q21MDhBAZcgLsK0nM00Tlv1qvifeUxvffmYm9eFCcJa0pFq8P239vQiFzUc8IQn03+HKZkovDHIhRbHt/ljoBiRfoCWxq44iXwuj1hGxvX5Q5aNPkskHoD8S/IQN2Gup65N/lumh8dosdi5nPtdldpoAkQBGcnUHt0sX42ZchvE0YaoM7NfPmOrysEeSzsUFDf2C3Ix+SP89lRAU9uD2dOfSTnDG6bT0yzHIw7WwSytRx5Ry9CvXaAwgCzPL55dlfdScScAJfOSBKO5hh3W7sKN9huV6esDt8z7qYsUIidvErZIoTHNkr gonzalen@yaaarrrr.local" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

if ! grep 'export PKG_PATH' /root/.profile > /dev/null 2>&1; then
    if [ $(uname -r) == "5.5" ]; then
        RELEASE=snapshots
    else
        RELEASE=`uname -r`
    fi
    PKG_PATH="http://openbsd.mirrorcatalogs.com/${RELEASE}/packages/`uname -m`"
    echo "export PKG_PATH=${PKG_PATH}" >> /root/.profile
fi

MYIPS=$(netstat -ni | \
        egrep -v "::|127.0.0.1|^Name|lo0|enc|pflog" | \
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
# Check for an update to the siteNN.tgz; be very careful!!!
if [[ ! -z ${API_SERVER} ]]; then
    MYSUM=$(md5 $0 | cut -d= -f2 | tr -d ' ')
    REMOTESUM=$(ftp -Vo- -r 5 http://${API_SERVER}/static/sitesum 2>/dev/null | tr -d ' ')
    if [ -z ${REMOTESUM} ]; then
        echo "FATAL: Could not get remote sum. Not going to check in"
        exit 1
    else
        if [[ ${REMOTESUM} != ${MYSUM} ]] ;then
            UPDATE_REQUIRED=1
            RELEASE=$(uname -r | tr -d '.')
            cd /tmp
            ftp -V http://${API_SERVER}/static/site${RELEASE}.tgz 2>/dev/null
            if [ -f /tmp/site${RELEASE}.tgz ]; then
                tar -zxvf /tmp/site${RELEASE}.tgz -C /
            else
                echo "FATAL: File was not downloaded properly"
                exit 1
            fi
        fi
    fi
    ensure_package "bash"
    ensure_package "python-2.7.6p0"

    # We didn't exit from the above routines, so we'll check in.
    API_COMMAND="checkin/${MYNAME}/$(date +%s)/${MYIPS}/${MYUNAME}"
    URL="http://${API_SERVER}/${API_COMMAND}"
    echo "hitting $URL"
    ftp -Vo- -r 2 ${URL} 2>/dev/null
fi
