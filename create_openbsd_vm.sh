#!/usr/bin/env bash

# This script is pretty specific to my environment; grep for 'Configure me' to see what you should
# change.
#
# This script does the following:
#  
#   generate_random_mac
#     generates a mac address manually so we can track this VM from the beginning of its life
#   
#   make_openbsd_answerfile ${MAC} ${VM}
#     Make an answer file using the MAC and VM name as seeds
#
#   make_virsh_script ${MAC} ${VM}
#     Make a shellscript we can ship to a remote host and run using the MAC and VM name as seeds
#
#   doit
#     Send the mentioned shellscript to a remote host and run it.
#

export TERM=vt100 # everyone should have this termdef.
if [[ "$(uname)" != "OpenBSD" ]]; then
    echo "This script is only meant to run on OpenBSD."
    exit 1
fi

function banner(){
    echo
    echo "********************************************************************************"
    echo
    echo "OpenBSD VM Creator"
    echo
    echo "********************************************************************************"
}

function set_random_host(){
    echo "INFO: Choosing random hypervisor for this vm"
    TARGET=${VALIDHYPERVISORS[$(( $RANDOM % ${#VALIDHYPERVISORS[@]} ))]}
    echo "INFO: Chose ${TARGET}"
}

function random_hex_value(){
    RANDOMHEX=$(printf "%X\n" $(( $RANDOM % 239 + 16)))
    if [[ ${#RANDOMHEX} -lt 1 ]]; then
        RANDOMHEX=0${RANDOMHEX}
    fi
    echo ${RANDOMHEX}
}

function generate_random_mac(){
    echo "INFO: generating a MAC address"
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
    # Configure me - you will likely want to change this answerfile
    echo "INFO: Writing seed file: ${FILE}"
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
    MAC=${1}
    VM=${2}
    # Configure me - the INSTALL_SCRIPT variable contains a variable called 'str'. I have to do this because the
    # version of virt-install on my centos hypervisors is not recent enough to support automagically adding 
    # a port to a vswitch. We print the XML for a domain without any NICs then manually add the interface stanza
    # via sed, like a caveman. If you are cool enough to be running openvswitch-trunk on centos65 like I am, just
    # make sure you set the bridge properly. Otherwise you can pretty much take out the 'str' crap and change 
    # --nonetworks in the virt-install command to something you would normally use, e.g. --network bridge=br2
    INSTALL_SCRIPT="./install_scripts/install-${VM}.sh"
    echo "INFO: Writing virsh shellscript: ${INSTALL_SCRIPT}"
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
    --name ${VM} \
    --ram 512 \
    --nonetworks \
    --disk path=/imgstorage/${VM}.img,size=3 \
    --graphics none \
    --boot hd \
    --print-xml \
    --os-type unix \
    --os-variant openbsd4 | \
    sed -e \"s#</devices>#\${str}#g\" > ${VM}.xml      " >> ${INSTALL_SCRIPT}
    echo "virsh define ${VM}.xml && virsh start ${VM}  " >> ${INSTALL_SCRIPT}
    echo "INFO: Wrote ${INSTALL_SCRIPT}"
}

function doit(){
    set_random_host
    echo "INFO: Sending script to remote target: ${TARGET}"
    scp ${INSTALL_SCRIPT} ${TARGET}: >/dev/null 2>&1
    echo "INFO: Executing script on ${TARGET}"
    ssh -q -tt ${TARGET} "bash ./${INSTALL_SCRIPT##.*/}" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "INFO: Successfully sent the command to define and start the VM"
        echo "INFO: Check the API for registration/further information"
    else
        echo "FATAL: Failure when trying to execute the remote script"
    fi
}

function usage(){
    # 0200 coding, deal with it!
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
    STEP="$(echo $STEP | tr ' ' '+')"             # Sanitize
    STEP="$(echo $STEP | tr -dc 'a-zA-Z0-9-+.' )" # Sanitize
    TARGET=$(ftp -Vo- -r 5 ${ROADSIGN} 2>/dev/null)
    if [ ! -z ${TARGET} ]; then
        API_CALL="buildlog/name=${VM}&start=$(date +%s)&step=${STEP}"
        URL="http://${TARGET}/${API_CALL}"
        ftp -Vo- -r5 ${URL} > /dev/null 2>&1
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

VALIDHYPERVISORS=( 192.168.20.102 192.168.20.104 192.168.20.105 )
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
