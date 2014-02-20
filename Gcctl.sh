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
    VMNAME="$1"
    HYPERVISOR=$( ${SQLITE3} ${DBFILE} "select hypervisor
                                        from vms where 
                                        realname='"${VMNAME}"';" )
    if [ -z ${HYPERVISOR} ]; then
        print_red "FATAL: Could not find a hypervisor for VM: ${VMNAME}\n"
        exit 1
    fi
    echo "removing $VMNAME on $HYPERVISOR"
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

DBFILE=ghetto.db

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
    list-vms)           list-vms;;
    list-hypervisors)   list-hypervisors;;
    delete-vm)          delete-vm ${1};;
    *)          print_red "Unrecognized command: ${command}\n"; exit 1;;
esac
