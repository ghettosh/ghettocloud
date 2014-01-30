OpenBSD Cloud
-------------

This is a lab project. In a sentence, it's a framework I use to rapidly provis-
ion OpenBSD virtual machines. 

It provides me with the ability to do the following:

    root@router:/data/serve # ./create_openbsd_vm.sh hobags
    
    ********************************************************************************
    OpenBSD VM Creator
    ********************************************************************************
    INFO: generating a MAC address
    INFO: Chose 00:de:ad:2d:7a:93
    INFO: Writing seed file: ./00:de:ad:2d:7a:93-install.conf
    INFO: Wrote ./00:de:ad:2d:7a:93-install.conf
    INFO: Root password will be:  a9aa938bd7e6
    INFO: Writing virsh shellscript: ./install_scripts/install-hobags.sh
    INFO: Wrote ./install_scripts/install-hobags.sh
    INFO: Choosing random hypervisor for this vm
    INFO: Chose 192.168.20.102
    INFO: Sending script to remote target: 192.168.20.102
    INFO: Executing script on 192.168.20.102
    INFO: Successfully sent the command to define and start the VM
    INFO: Check the API for registration/further information

Then about 6 minutes later, a vm called hobag contacts my deployment server and 
says it's ready, and gives a few bits of information (ip, uname, etc.)

To Do
-----

  - Write a proper REST API to handle incoming 'registrations' 
  - implement "firstrun" capabilities into the 'checkin.sh' script for install-
    ing packages/ports/other post-install configurations
  - add some getopt funcitonality to allow for customizatoin of the virt-install
    command
  - Expand checkin.sh to send a lot more data
  - Integrate configuration management into the mix

Pre Requisites
--------------

  * 1 or more Linux boxes with libvirt,virt-install installed
  * at least one OpenBSD machine serving as at least a DHCP server with at lea-
    st 1GB of storage

This directory represents a few things:

  * the tftpboot directory hosted from a next-server
  * The webroot hosted from that same next-server
  * A place to run your vm creation scripts from
  * This directory must be available from http as well

Description of files
--------------------

My production deployment looks like this:

    root@router:/data/serve # ls -l
    total 96
    drwxr-xr-x  8 root  wheel   512 Jan 30 12:46 .git
    -rw-r--r--  1 root  wheel    81 Jan 30 11:07 .gitignore
    -rw-r--r--  1 root  wheel   403 Jan 30 08:05 00:de:ad:54:52:49-install.conf
    -rw-r--r--  1 root  wheel   403 Jan 30 08:05 00:de:ad:67:71:41-install.conf
    -rw-r--r--  1 root  wheel   403 Jan 30 08:04 00:de:ad:76:c7:33-install.conf
    -rw-r--r--  1 root  wheel   396 Jan 30 05:35 00:de:ad:89:a0:8c-install.conf
    -rw-r--r--  1 root  wheel   403 Jan 30 08:05 00:de:ad:db:b4:f7-install.conf
    -rw-r--r--  1 root  wheel  3344 Jan 30 12:54 README.md
    lrwxr-xr-x  1 root  wheel    40 Jan 28 05:05 auto_install -> ./openbsd-mirror-snapshots-amd64/pxeboot
    lrwxr-xr-x  1 root  wheel    39 Jan 28 04:49 bsd -> ./openbsd-mirror-snapshots-amd64/bsd.rd
    -rwxr-xr-x  1 root  wheel  6435 Jan 30 12:04 create_openbsd_vm.sh
    drwxr-xr-x  2 root  wheel   512 Jan 30 12:26 etc
    -rw-r--r--  1 root  wheel   245 Jan 28 05:15 install.conf
    drwxr-xr-x  2 root  wheel   512 Jan 30 08:05 install_scripts
    drwxr-xr-x  2 root  wheel   512 Jan 30 06:12 openbsd-mirror-5.4-amd64
    drwxr-xr-x  2 root  wheel  1024 Jan 30 06:35 openbsd-mirror-snapshots-amd64
    lrwxr-xr-x  1 root  wheel    40 Jan 28 04:49 pxeboot -> ./openbsd-mirror-snapshots-amd64/pxeboot
    drwxr-xr-x  2 root  wheel  1536 Jan 30 12:26 site-backups
    -rwxr-xr-x  1 root  wheel  2597 Jan 30 11:28 sync_openbsd_repo.sh
    -rwxr-xr-x  1 root  wheel  1531 Jan 30 12:26 update_site_file.sh
    drwxr-xr-x  3 root  wheel   512 Jan 30 04:56 usr
    drwxr-xr-x  3 root  wheel   512 Jan 30 04:54 var


MAC-ADDRESS-install.conf
------------------------------
When the OpenBSD VM boots up, autoinstaller will try to hit the next-server on 
port 80 and request this file. It contains answers to the questions you are as-
ked in an interactive openbsd installation. This file is generated on  the fly
by create_openbsd_vm.sh.


README.md
---------
The readme, this file.

auto_install
------------
The PXE loader need to be linked/coped to this file, I forgot why, but I belie-
ve it's to differentiate between an auto-install and an auto-upgrade.


auto_install -> ./openbsd-mirror-snapshots-amd64/pxeboot
pxeboot -> ./openbsd-mirror-snapshots-amd64/pxeboot

bsd
---
The 'bsd' file is the 'kernel' that is sent by the pxe loader. It's a ramdisk 
containing the installation image. In my case, it's a symlink to the bsd.rd of 
the distribution I want to boot by default:

    bsd -> ./openbsd-mirror-snapshots-amd64/bsd.rd

etc/ usr/ var/
--------------
These directories are used as both the ramdisk configuration (only /etc/boot.c-
onf) and site configuration.

install.conf
------------
A default install.conf, in case the auto-installer can't find <mac>-install.conf

install_scripts
---------------
This is where the 'build it' scripts go to. Prior to building a VM, the script 
to actually built it is staged here. Then it is scp'd over to the destination 
(a random host) and run. You can use this directory to rebuild or troubleshoot 
a failed build.

openbsd-mirror-version-arch
----------------
These are the mirrored directories of public mirrors. We'll pull the install 
media off of these directories.

pxeboot
-------
Symlink to the particular distribution's pxeboot file. This is required to pxe-
boot openbsd VMs.

site-backups
------------
When a new site${version}.tgz file is made, the old one is backed up here.

create_openbsd_vm.sh
--------------------
This script is the one that actually creates the VMs on the remote (randomly 
selected) hosts. It stages up a shellscript in ./install_scripts, scp's it over
to the target, then runs it over there. Simple, not pretty, but it works. 

sync_openbsd_repo.sh
--------------------
This script creates a series of directories called openbsd-mirror-${VERSION}-
${ARCH} and contains the same directories you would see on an official openbsd 
mirror. We need this because we don't want to rape a mirror every time we want 
to build a box. Your newly built VMs will build themselves using these files.


update_site_file.sh
-------------------
Creates a new site${version}.tgz file, and backs up the old one to ./site-back-
ups. The script also ensures the index.txt is up-to-date. The site${version}.tgz 
file goes with the rest of the distribution sets.
