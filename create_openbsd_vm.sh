#!/usr/bin/env bash

export TERM=xterm
if [[ "$(uname)" != "OpenBSD" ]]; then
    echo "Sorry, this script is only meant to run on OpenBSD."
    exit 1
fi

function banner(){
    echo
    echo "********************************************************************************"
    echo "OpenBSD VM Creator"
    echo "********************************************************************************"
}

function random_host(){
    echo ${VALIDHYPERVISORS[$(( $RANDOM % ${#VALIDHYPERVISORS[@]} ))]}
}

function random_hex_value(){
    RANDOMHEX=$(printf "%X\n" $(( $RANDOM % 239 + 16)))
    if [[ ${#RANDOMHEX} -lt 1 ]]; then
        RANDOMHEX=0${RANDOMHEX}
    fi
    echo ${RANDOMHEX}
}

function generate_random_mac(){
    MAC=( '00' 'de' 'ad' )
    for i in {1..3}; do
        MAC+=( $(random_hex_value) )
    done
    MAC=$( echo ${MAC[@]} | tr ' ' ':' )
    MAC=$( echo ${MAC} | tr 'A-Z' 'a-z' )
    echo "INFO: Chose ${MAC}"
}


function make_openbsd_answerfile(){
    MAC=$1
    NAME=$2
    FILE=./${MAC}-install.conf
    PASSWORD=$(date +%s | md5 | cut -c -12)
    if [ ! -z $ANSWER_FILE ]; then
        echo "INFO: Detected user-specified answer file. using that"
        echo "INFO: cp ${ANSWER_FILE} ${FILE}"
        cp ${ANSWER_FILE} ${FILE} 
        return
    fi
    echo "INFO: Writing ${FILE}"
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
EOT
    echo "INFO: Wrote ${FILE}"
    echo "INFO: Root password will be: $(grep ^password ${FILE} | cut -d= -f2)"
}

function make_virsh_script(){
    MAC=$1
    VM=$2
    INSTALL_SCRIPT="./install_scripts/install-${VM}.sh"
    echo "INFO: Writing ${INSTALL_SCRIPT}"
    echo "str=\"  <interface type='bridge'>\n\"                                        " > ${INSTALL_SCRIPT}    
    echo "str+=\"      <mac address='${MAC}'/>\n\"                                     " >> ${INSTALL_SCRIPT}      
    echo "str+=\"      <source bridge='br100'/>\n\"                                    " >> ${INSTALL_SCRIPT}      
    echo "str+=\"      <virtualport type='openvswitch'>\n\"                            " >> ${INSTALL_SCRIPT}          
    echo "str+=\"      </virtualport>\n\"                                              " >> ${INSTALL_SCRIPT}  
    echo "str+=\"      <model type='virtio'/>\n\"                                      " >> ${INSTALL_SCRIPT}      
    echo "str+=\"    </interface>\n\"                                                  " >> ${INSTALL_SCRIPT} 
    echo "str+=\"  </devices>\"                                                        " >> ${INSTALL_SCRIPT}
    echo "virt-install --connect qemu:///system \
    --virt-type kvm \
    --name ${VM} \
    --ram 512 \
    --nonetworks \
    --disk path=/imgstorage/${VM}.img,size=3 \
    --graphics none \
    --boot hd \
    --print-xml \
    --os-type unix \
    --os-variant openbsd4 | sed -e \"s#</devices>#\${str}#g\" > ${VM}.xml              " >> ${INSTALL_SCRIPT}
    echo "virsh define ${VM}.xml && virsh start ${VM}                                  " >> ${INSTALL_SCRIPT}
    echo "INFO: Wrote ${INSTALL_SCRIPT}"
}

function doit(){
    echo "INFO: Choosing random destination for this host"
    TARGET="$(random_host)"
    echo "INFO: Chose ${TARGET}"
    
    echo "INFO: Sending script to remote target: ${TARGET}"
    scp ${INSTALL_SCRIPT} ${TARGET}:
    
    echo "INFO: Executing script on ${TARGET}"
    ssh -q -tt ${TARGET} "bash ./${INSTALL_SCRIPT##.*/}"
}

function usage(){
    banner
    echo
    tput setf 4
    echo "Usage: [ANSWER_FILE=/path/to/my/file] $0 <vm name>"
    tput sgr0
    tput setf 6
    echo
    echo "Examples:"
    echo
    tput setf 5
    echo "  create a vm called hippo using an auto-generated answerfile:"
    tput sgr0
    echo "  $0 hippo"
    echo
    tput setf 5
    echo "  Create a vm called doge using a specified answer file:"
    tput sgr0
    echo "  ANSWER_FILE=/home/me/answerfiles/doge.conf $0 doge"
    echo
    exit 1
}

function log_step(){
    STEP=${1}
    STEP="$(echo $STEP | tr ' ' '+')"           # Sanitize
    STEP="$(echo $STEP | tr -dc 'a-zA-Z0-9-+.' )" # Sanitize
    URL="http://$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)/buildlog/name=${VM}&start=$(date +%s)&step=${STEP}"
    ftp -Vo- -r5 ${URL} > /dev/null 2>&1
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

VALIDHYPERVISORS=( 192.168.20.102 192.168.20.103 )
ROADSIGN="http://ghetto.sh/roadsign.txt"

banner
generate_random_mac
log_step "Generating random mac address"
make_openbsd_answerfile ${MAC} ${VM}
log_step "Made answer file"
make_virsh_script ${MAC} ${VM}
log_step "Made virsh script"
doit 
log_step "Started the build on ${TARGET}"
