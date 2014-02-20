#!/usr/bin/env bash

###############################################################################
#
# Functions
#

function print_blue(){ printf "$(tput setf 1)$@$(tput sgr0)"; }
function print_green(){ printf "$(tput setf 2)$@$(tput sgr0)"; }
function print_blue(){ printf "$(tput setf 3)$@$(tput sgr0)"; }
function print_red(){ printf "$(tput setf 4)$@$(tput sgr0)"; }
function print_pink(){ printf "$(tput setf 5)$@$(tput sgr0)"; }
function print_yellow(){ printf "$(tput setf 6)$@$(tput sgr0)"; }
function print_white(){ printf "$(tput setf 7)$@$(tput sgr0)"; }

function usage(){
  print_red "Usage:\n"
  echo " $0 <-c command> "
  print_red "Commands are any one of the following:\n"
  echo "  list-vms"
  echo "  delete-vm <hash>"
  echo "  list-hypervisors"
  echo "  show-checkin <vm name>"
  echo "  show-bootlog <vm name>"
  exit 1
}

function list-vms(){
  if [[ $DEBUG ]]; then
    print_yellow "DEBUG: Command -> $command\n"
  fi
  ${SQLITE3} -header -column ${DBFILE} "select * from vms;"
}
function list-hypervisors(){
  if [[ $DEBUG ]]; then
    print_yellow "DEBUG: Command -> $command\n"
  fi
  printf "Hypervisors\n-----------\n"
  ${SQLITE3} -column ${DBFILE} "select distinct(hypervisor) from vms;"
}

function delete-vm(){
  VM="$1"
  HYPERVISOR=$( ${SQLITE3} ${DBFILE} "select hypervisor
                    from vms where 
                    realname='"${VM}"';" )
  VMID=$(${SQLITE3} ${DBFILE} "SELECT id FROM vms WHERE realname='"${VM}"';")
  if [[ -z ${HYPERVISOR} ]] || [[ -z ${VMID} ]]; then
    print_red "FATAL: Could not find a hypervisor or id for VM: ${VM}\n"
    exit 1
  fi
  print_pink "WARN:"; printf " removing ${VM} on ${HYPERVISOR}\n"
  destroy_cmd="ssh -q -tt ${HYPERVISOR} virsh destroy ${VM}"
  undefine_cmd="ssh -q -tt ${HYPERVISOR} virsh undefine ${VM} --managed-save"
  rmimage_cmd="ssh -q -tt ${HYPERVISOR} rm -f /imgstorage/${VM}.img"
  dbdrop_cmd=""
  print_blue "INFO: Destroying the VM..."
  ${destroy_cmd} > /dev/null 2>&1 && echo "ok" || { echo "failed"; exit 1; }
  print_blue "INFO: Undefining the VM..."
  ${undefine_cmd} > /dev/null 2>&1 && echo "ok" || { echo "failed"; exit 1; }
  print_blue "INFO: deleting the VM's backing storage..."
  ${rmimage_cmd} > /dev/null 2>&1 && echo "ok" || { echo "failed"; exit 1; }
  print_blue "INFO: Dropping host from database..."
  ${SQLITE3} ${DBFILE} "DELETE FROM vms WHERE realname='"${VM}"';"
  VERIFY=$(${SQLITE3} ${DBFILE} "SELECT count() FROM vms WHERE realname='"${VM}"';")
  if [[ ${VERIFY} -ne 0 ]]; then
    echo "failed"; exit 1;
  else
    echo "ok"
  fi
  print_blue "INFO:"; printf " successfully removed ${VM}"
}
  

#
# End Functions
#

###############################################################################
#
# Variables
#

ROADSIGN="http://ghetto.sh/roadsign.txt"
API_HEAD="$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)"
OS="$(uname)"

SQLITE3=`which sqlite3 2>/dev/null`
SQLITE3=${SQLITE3:?FATAL: no sqlite3 found}

DBFILE=/data/serve/ghettoapi/cgi/ghetto.db

#
# End Variables
#

###############################################################################
#
# Checks and getopt
#

if [[ -z ${API_HEAD} ]]; then
  print_red "FATAL: Could not contact the API head\n"
  exit 1
fi

if [[ $DEBUG ]]; then
  print_yellow "DEBUG: API Head -> ${API_HEAD}\n"
fi

if [[ "${OS}" != "OpenBSD" ]]; then                      
  print_red "FATAL: This script is only meant to run on OpenBSD\n"      
  exit 1                                    
fi 

while getopts ":c:d" o; do
  case "${o}" in
    c)
      command=${OPTARG}
      ;;
    d)  DEBUG=1;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${command}" ]; then
  usage
fi


###############################################################################
#
# main()
#

case ${command} in
  list-vms)       list-vms;;
  list-hypervisors)   list-hypervisors;;
  delete-vm)      delete-vm ${1};;
  *)      print_red "Unrecognized command: ${command}\n"; exit 1;;
esac
