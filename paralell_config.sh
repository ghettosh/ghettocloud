#!/usr/bin/env bash

#
# A script to kick off multiple 'cdist config' instances via gnu parallel.
#

GCCTL=/data/serve/gcctl
CDIST_BIN=/data/cdist/bin/cdist
CDIST_OPTS=" -v config "
THREADS=
LOGFILE=`mktemp`
PARALLEL=`which parallel 2>/dev/null` || \
  { echo "please install gnu parallel"; exit 1; }
START=$(date +%s)

function cleanup(){
  END=$(date +%s)
  RUNTIME=$(( END - START))
  echo -e "\n[ FATAL ]: Signal detected after ${RUNTIME} seconds"
  echo -e "[ FATAL ]: Cleaning up..."
  printf "[ FATAL ]: Removing logfile..."
  rm -f $LOGFILE > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "success"
  else
    echo "failure"
  fi
  printf "[ FATAL ]: Attempting to stop GNU Parallel ($PARALLEL_PID) ..."
  kill -KILL $PARALLEL_PID > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "success"
  else
    echo "failure"
  fi
  
  exit 145
}

function waitforit {
  # tastefully stolen from a stack overflow question !
  local pid=$1
  local delay=0.5
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf "%c" "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b"
  done
  printf "  \b"
}

trap cleanup SIGINT SIGKILL SIGTERM

HOSTS=()
for HOST in $( ${GCCTL} -c list-vms | awk '/running/{print $4}' ); do
  printf "%-80s\n" "[ INFO ]: Adding host to the array: ${HOST}"
  HOSTS+=( ${HOST} )
done

if [[ -z ${THREADS} ]]; then
  THREADS=${#HOSTS[@]}
  printf "[ INFO ]: No amount of threads specified, using ${THREADS}\n"
fi

printf "[ INFO ]: Running configuration on ${#HOSTS[@]} hosts...\n"
printf "[ INFO ]: Logging output to ${LOGFILE}\n"
printf "[ INFO ]: Executing "
parallel -v -j ${THREADS} \
   " 
    2>&1 ${CDIST_BIN} ${CDIST_OPTS} {} | while read L; do
      printf \"[ {} ] (\$(date +%D_%H%M)) \$L\n\"; 
    done
   "  ::: ${HOSTS[@]} > ${LOGFILE} &

waitforit $!
END=$(date +%s)
RUNTIME=$(( END - START ))

echo -e \
  "\n[ INFO ]: Finished run in ${RUNTIME} seconds, check ${LOGFILE} for output"
