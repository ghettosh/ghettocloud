#!/usr/bin/env bash

# This script is pretty specific to my environment; grep for 'Configure me' to 
# see what you should change
#
# This script does the following:
#  
#   generate_random_mac
#     generates a mac address manually so we can track this VM from the 
#     beginning of its life
#   
#   make_openbsd_answerfile ${MAC} ${VM}
#     Make an answer file using the MAC and VM name as seeds
#
#   make_virsh_script ${MAC} ${VM}
#     Make a shellscript we can ship to a remote host and run using the MAC and
#     VM name as seeds
#
#   doit
#     Send the mentioned shellscript to a remote host and run it.
#

function print_blue(){ printf "$(tput setf 1)$@$(tput sgr0)"; }
function print_green(){ printf "$(tput setf 2)$@$(tput sgr0)"; }
function print_blue(){ printf "$(tput setf 3)$@$(tput sgr0)"; }
function print_red(){ printf "$(tput setf 4)$@$(tput sgr0)"; }
function print_pink(){ printf "$(tput setf 5)$@$(tput sgr0)"; }
function print_yellow(){ printf "$(tput setf 6)$@$(tput sgr0)"; }
function print_white(){ printf "$(tput setf 7)$@$(tput sgr0)"; }

export TERM=xterm # everyone should have this termdef.
if [[ "$(uname)" != "OpenBSD" ]]; then
    print_red "FATAL: This script is only meant to run on OpenBSD\n"
    exit 1
fi

function banner(){
    print_pink "\tGhetto.sh OpenBSD VM Creator\n"
}

function set_random_host(){
    print_blue "INFO:"; printf " Choosing random hypervisor for this vm..."
    TARGET=${VALIDHYPERVISORS[$(( $RANDOM % ${#VALIDHYPERVISORS[@]} ))]}
    echo "chose ${TARGET}"
}

function set_least_busy_host(){
    TEMPFILE=`mktemp`
    print_blue "INFO:";
        printf " Choosing the least loaded hypervisor for this vm..."
    TARGET=
    for HYPERVISOR in ${VALIDHYPERVISORS[@]}; do
        VMCOUNT="$(ssh -q ${HYPERVISOR} virsh list 2>/dev/null | \
            grep 'running' | wc -l)" 
        if [ -z ${VMCOUNT} ]; then
            VMCOUNT=NULL
        fi
        echo "${HYPERVISOR} ${VMCOUNT}" >> $TEMPFILE
    done
    grep NULL $TEMPFILE > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        print_yellow "WARN:";
            printf " One or more hypervisor didn't report a vm count\n"
    fi
    TARGET="$(sort -nrk2 $TEMPFILE | tail -1 | awk '{print $1}')"
    if [ -z ${TARGET} ]; then
        print_red "FATAL: Could not determine a hypervisor for the vm on\n"
        print_red "DEBUG: Output of the temp file"
        cat $TEMPFILE | while read L; do
            print_red "$L"
        done
        exit 1
    fi
    echo "chose ${TARGET}"
    rm -f $TEMPFILE
}

function random_hex_value(){
    RANDOMHEX=$(printf "%X\n" $(( $RANDOM % 239 + 16)))
    if [[ ${#RANDOMHEX} -lt 1 ]]; then
        RANDOMHEX=0${RANDOMHEX}
    fi
    echo ${RANDOMHEX}
}

function generate_random_mac(){
    print_blue "INFO:"; printf " generating a MAC address..."
    MAC=( '00' 'de' 'ad' )
    for i in {1..3}; do
        MAC+=( $(random_hex_value) )
    done
    MAC=$( echo ${MAC[@]} | tr ' ' ':' )
    MAC=$( echo ${MAC} | tr 'A-Z' 'a-z' )
    echo "chose ${MAC}"
}

function make_openbsd_answerfile(){
    MAC=$1
    NAME=$2
    FILE=/data/serve/${MAC}-install.conf
    PASSWORD=$(date +%s | md5 | cut -c -12)
    if [ ! -z $ANSWER_FILE ]; then
        print_yellow "INFO:"
            printf " Detected user-specified answer file. using that\n"
        cp ${ANSWER_FILE} ${FILE} 
        return
    fi
    # Configure me - you will likely want to change this answerfile template
    print_blue "INFO:"; printf " Writing seed file: ${FILE}..."
    cat << EOT > ${FILE}
system hostname = ${NAME}
password for root account = ${PASSWORD}
network interfaces = vio0
IPv4 address for vio0 = dhcp
Do you expect to run the X Window System? = yes
Change the default console to com0? = yes
What timezone are you in? = US/Mountain
Location of sets? = http
server? = 192.168.10.1
server directory? = openbsd-mirror-snapshots-amd64/
Set name(s)? = site55.tgz
Install sets anyway? = yes
Directory does not contain SHA256.sig. Continue without verification? = yes
EOT
    echo "ok"
}

function make_virsh_script(){
    MAC=${1}
    VM=${2}
    VMHASH=$(echo ${RANDOM}${VM}${RANDOM} | md5)
    INSTALL_SCRIPT="/data/serve/install_scripts/install-${VMHASH}.sh"
    print_blue "INFO:"; printf " Writing shellscript: ${INSTALL_SCRIPT}..."
    echo "str=\"  <interface type='bridge'>\n\"          " > ${INSTALL_SCRIPT}    
    echo "str+=\"   <mac address='${MAC}'/>\n\"         " >> ${INSTALL_SCRIPT}      
    echo "str+=\"   <source bridge='br100'/>\n\"        " >> ${INSTALL_SCRIPT}      
    echo "str+=\"   <virtualport type='openvswitch'>\n\"" >> ${INSTALL_SCRIPT}          
    echo "str+=\"   </virtualport>\n\"                  " >> ${INSTALL_SCRIPT}  
    echo "str+=\"   <model type='virtio'/>\n\"          " >> ${INSTALL_SCRIPT}      
    echo "str+=\"  </interface>\n\"                     " >> ${INSTALL_SCRIPT} 
    echo "str+=\"  </devices>\"                         " >> ${INSTALL_SCRIPT}
    echo "virt-install --connect qemu:///system \
    --virt-type kvm \
    --name ${VMHASH} \
    --os-type unix \
    --os-variant openbsd4 \
    --ram 512 \
    --nonetworks \
    --disk path=/imgstorage/${VMHASH}.img,size=3 \
    --graphics none \
    --boot hd \
    --print-xml \
    --os-type unix \
    --os-variant openbsd4 | sed -e \"s#</devices>#\${str}#g\" > ${VMHASH}.xml" \
        >> ${INSTALL_SCRIPT}
    echo "virsh define ${VMHASH}.xml && virsh start ${VMHASH}" \
        >> ${INSTALL_SCRIPT}
    echo "ok"
}

function doit(){
    # set_random_host
    set_least_busy_host
    print_blue "INFO:"; printf " Sending script to remote target: ${TARGET}..."
    scp ${INSTALL_SCRIPT} ${TARGET}: >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "ok"
    else
        echo "failed"
        exit 1
    fi
    print_blue "INFO:"; printf " Executing script on ${TARGET}..."
    ssh -q -tt ${TARGET} "bash ./${INSTALL_SCRIPT//*\/}" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "ok"
        if [[ $USING_DATABASE == 1 ]]; then
          print_blue "INFO:"; printf " Updating local database...(1 of 1)..."
          ${SQLITE3} ${DBFILE} "INSERT INTO vms ( realname,
                                                  state,
                                                  macaddr,
                                                  rootpw,
                                                  hypervisor,
                                                  creationdate ) VALUES (
                                                    '${VMHASH}',
                                                    'in_build',
                                                    '${MAC}',
                                                    '${PASSWORD}',
                                                    '${TARGET}',
                                                    '$(date +%s)')" && \
          echo "ok" || echo "failed"

          #print_blue "INFO:"; printf " Updating local database...(2 of 2)..."
          #${SQLITE3} ${DBFILE} "INSERT INTO events (  state, 
          #                                            macaddr )
          #                      VALUES (  'in_build', 
          #                                '${MAC}')" && \
          #echo "ok" || echo "failed"
        fi
    else
        print_red "FATAL: Failure when trying to execute the remote script\n"
    fi
}

function usage(){
    banner
    print_red "Usage\n"
    print_red "-----\n"
    print_yellow " [ANSWER_FILE=/path/to/my/file] $0 <vm name>\n"
    print_red "\nExamples\n"
    print_red "--------\n"
    print_white "  create a vm called hippo using an auto-generated answerfile:\n"
    print_yellow "  $0 hippo\n\n"
    print_white "  Create a vm called doge using a specified answer file:\n"
    print_yellow "  ANSWER_FILE=/home/me/answerfiles/doge.conf $0 doge\n\n"
    exit 1
}

function log_step(){
    STEP=${1}                                                                   
    STEP="$(echo $STEP | tr ' ' '+')"             # Sanitize                    
    STEP="$(echo $STEP | tr -dc 'a-zA-Z0-9-+.' )" # Sanitize                    
    TARGET=$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)                             
    if [ ! -z ${TARGET} ]; then                                                 
        API_CALL="buildlog?vm=${VM}&date=$(date +%s)&step=${STEP}"                           
        URL="${TARGET}/${API_CALL}"                                      
        OUTPUT=$(ftp -Vo- -r5 ${URL} 2>/dev/null)                               
        if [[ -z ${OUTPUT} ]]; then                                             
            print_red "FATAL: Failed to log to build API on step: $STEP\n" 
        fi                                                                      
    fi                                                                          
}

#
# main()
#

ARGC=$#
if [[ $ARGC -ne 1 ]]; then
    usage
elif echo ${1} | egrep "^\-|\-h|\-\-help|\-\?" > /dev/null 2>&1; then   
    usage
else
    VM=$1
fi

USING_DATABASE=1              # Set this value to 1 to update a sqlite db
                              # leave it at zero to use your own stuff
VALIDHYPERVISORS=( 192.168.20.10{2,3,4,5} )
ROADSIGN="http://ghetto.sh/roadsign.txt"

SQLITE3=`which sqlite3 2>/dev/null`
SQLITE3=${SQLITE3:?FATAL: no sqlite3 found}

if [[ ${USING_DATABASE} -eq 1 ]]; then
  DBFILE=/data/serve/ghettoapi/cgi/ghetto.db   # Configure me
  DBFILE=${DBFILE:?$(usage)}
fi

banner

generate_random_mac && \
make_openbsd_answerfile ${MAC} ${VM} && \
make_virsh_script ${MAC} ${VM} && \
doit 

