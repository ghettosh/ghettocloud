#!/usr/bin/env bash
#
# A little script to backup/generate a new siteNN.tgz file for every time you update 
# the site.tgz sets.

SITE_DIRS=( 'usr/' 'var/' 'etc/' )                         # Configure me - tar these dirs up (relative to .)
DISTRIBUTIONS_TO_UPDATE=( '5.4-amd64' 'snapshots-amd64' )  # Configure me - Put the site file in openbsd-mirror-$here
SITE_BACKUPS="./site-backups/"                             # Configure me - backup the old site.tgz file here     
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
    CMD="cd openbsd-mirror-${DISTRIBUTION} ; ls -l > index.txt"
    echo "INFO: Running $CMD"
    ( $CMD ) && { echo "INFO: Success"; } || { echo "INFO: Failed"; }
    echo
done

