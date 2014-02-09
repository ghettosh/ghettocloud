#!/usr/bin/env bash
#
# A little script to backup/generate a new siteNN.tgz file for every time you update 
# the site.tgz sets.

SITE_DIRS=( 'usr/' 'var/' 'etc/' )                         # Configure me - tar these dirs up (relative to .)
DISTRIBUTIONS_TO_UPDATE=( '5.4-amd64' 'snapshots-amd64' )  # Configure me - Put the site file in openbsd-mirror-$here
SITE_BACKUPS="./site-backups/"                             # Configure me - backup the old site.tgz file here     

echo "INFO: Updating API deployment box"
API_HEAD=$(ftp -Vo- -r5 http://ghetto.sh/roadsign.txt 2>/dev/null | \
            cut -d: -f1)
API_SSHPORT='20480'
API_SSHUSER='root'
SCP_OPTIONS=" -P${API_SSHPORT} "
SSH_OPTIONS=" -p${API_SSHPORT} -l${API_SSHUSER} "
API_REMOTE_SUM="/home/apiadmin/ghettosh-flask-api/api/static/sitesum"
API_REMOTE_FILE="/home/apiadmin/ghettosh-flask-api/api/static/"
CHECKIN_MD5=$(md5 usr/bin/checkin.sh | cut -d= -f2 | tr -d ' ')
REMOTESUM=$(ssh ${SSH_OPTIONS} ${API_HEAD} cat ${API_REMOTE_SUM}) 
if [[ ${CHECKIN_MD5} != ${REMOTESUM} ]]; then
    CMD="ssh ${SSH_OPTIONS} ${API_HEAD} echo ${CHECKIN_MD5} > ${API_REMOTE_SUM}"
    echo "INFO: Running $CMD"                                                   
    $CMD && { echo "INFO: Success"; } || { echo "INFO: Failed"; }               
else
    echo "INFO: Up-to-date"
fi

mkdir -p ${SITE_BACKUPS} > /dev/null 2>&1
for DISTRIBUTION in ${DISTRIBUTIONS_TO_UPDATE[@]}; do
    echo
    if [[ ${DISTRIBUTION} =~ "snapshots" ]]; then
        VERSION=55                                         # Configure me - Make sure this matches -current.
    else
        VERSION=${DISTRIBUTION/-*}
        VERSION=${VERSION/\./}
    fi
    LINE="INFO: Doing ${DISTRIBUTION} (${VERSION})"
    echo -e ${LINE}
    perl -e 'print "=" x '${#LINE}'; print "\n";'
    CMD="`which cp` openbsd-mirror-${DISTRIBUTION}/site${VERSION}.tgz ${SITE_BACKUPS}/backup-site${VERSION}-$(date +%s).tgz"
    echo "INFO: Running $CMD"
    $CMD && { echo "INFO: Success"; } || { echo "INFO: Failed"; }

    CMD="`which tar` -cczf openbsd-mirror-${DISTRIBUTION}/site${VERSION}.tgz ${SITE_DIRS[@]}"
    echo "INFO: Running $CMD"
    $CMD && { echo "INFO: Success"; } || { echo "INFO: Failed"; }

    CMD="`which scp` ${SCP_OPTIONS} openbsd-mirror-${DISTRIBUTION}/site${VERSION}.tgz ${API_SSHUSER}@${API_HEAD}:${API_REMOTE_FILE}"
    echo "INFO: Running $CMD"
    $CMD && { echo "INFO: Success"; } || { echo "INFO: Failed"; }

    CMD="cd openbsd-mirror-${DISTRIBUTION} ; ls -l > index.txt"
    echo "INFO: Running $CMD"
    ( $CMD ) && { echo "INFO: Success"; } || { echo "INFO: Failed"; }

    echo
done

