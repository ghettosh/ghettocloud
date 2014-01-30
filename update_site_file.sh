#!/usr/bin/env bash
SITE_DIRS=( 'usr/' 'var/' 'etc/' )
DISTRIBUTIONS_TO_UPDATE=( '5.4-amd64' 'snapshots-amd64' )
SITE_BACKUPS="./site-backups/"
for DISTRIBUTION in ${DISTRIBUTIONS_TO_UPDATE[@]}; do
    echo
    if [[ ${DISTRIBUTION} =~ "snapshots" ]]; then
        VERSION=55
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

