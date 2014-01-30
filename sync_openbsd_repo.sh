#!/usr/bin/env bash

# Quick and ugly

declare -A files
declare -a flavors
declare -a arches
declare -a supported
if [[ "$(uname)" != "OpenBSD" ]]; then
    echo "This script is meant to only be run from OpenBSD."
    exit 1
fi

#CURL=`which curl` > /dev/null 2>&1 \
#    || { echo "FATAL: You need curl to continue"; exit 1; }
SHA256SUM=`which sha256` 

arches=( amd64 )            # Configure me - Download these architectures
flavors=( 5.4 snapshots )   # Configure me - for these versions of OpenBSD

for ARCH in ${arches[@]}; do
    for FLAVOR in ${flavors[@]}; do
      echo "[+] Doing flavor: ${FLAVOR} [${ARCH}] at $(date +%h-%d,%H:%M)"
      files=()
      URL=http://openbsd.mirrorcatalogs.com/${FLAVOR}/${ARCH}/             # Configure me - set the mirror URL to somewhere close to you
      SHAURL=$URL/SHA256
      MIRRORDIR=./openbsd-mirror-${FLAVOR}-${ARCH}
      TMPFILE=`mktemp`
      UPDATED=0
      
      if [[ ! -d ${MIRRORDIR} ]]; then
        mkdir ${MIRRORDIR}
      fi
      
      # $CURL -sq $SHAURL > $TMPFILE 2>&1 || \
      ftp -Vo ${TMPFILE} ${SHAURL} 2>&1 || \
        { echo "FATAL: could not get the remote manifest. exiting"; \
          exit 1; }
      # We need to use a tempfile because ${files[@]} won't inherit otherwise
      while read LINE; do
        F=$( echo $LINE | sed -e 's/(//g;s/)//g' | awk '{print $2}')
        SHASUM=$( echo $LINE | awk '{print $4}' )
        files[$F]=$SHASUM
      done < $TMPFILE
      rm -f $TMPFILE
      
      for ITEM in ${!files[@]}; do
        printf "[${FLAVOR}] checking $ITEM... "
        if [[ ! -f $MIRRORDIR/${ITEM} ]]; then
          UPDATED=1
          # ${CURL} -sq ${URL}/${ITEM} > ${MIRRORDIR}/${ITEM} && \
          ftp -Vo ${MIRRORDIR}/${ITEM} ${URL}/${ITEM} && \
            { echo "downloaded"; } || { echo "failed"; }
        else
          if [[ -f ${MIRRORDIR}/.sums ]]; then 
            # CURRENTSUM=$( grep -E "[[:space:]]+${ITEM}$" ${MIRRORDIR}/.sums | awk '{print $1}' )
            CURRENTSUM=$( grep -E "[[:space:]]+\(${ITEM}\)[[:space:]]" ${MIRRORDIR}/.sums | awk '{print $4}' )
          else
            CURRENTSUM=$( ${SHA256SUM} ${MIRRORDIR}/${ITEM} | awk '{print $5}')
          fi
          if [[ ${CURRENTSUM} != ${files[$ITEM]} ]]; then
            UPDATED=1
            printf "update required... "
            # ${CURL} -sq ${URL}/${ITEM} > ${MIRRORDIR}/${ITEM}  && \
            ftp -Vo ${MIRRORDIR}/${ITEM} ${URL}/${ITEM} && \
            echo "ok"
          else
            echo "update not required"
          fi
        fi
      done
      
      if [[ ${UPDATED} -eq 1 ]]; then
        printf "[+] something was updated - generating new sums... "
        ( cd $MIRRORDIR && { ${SHA256SUM} * > .sums && { echo "ok"; } || { echo "failed"; } } )
      fi
    done
done
