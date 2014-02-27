OpenBSD Cloud
-------------

This is a lab project. In a sentence, it's a framework I use to rapidly
provision OpenBSD virtual machines.

It provides me with the ability to do the following:

    root@dnpcor4rtr00:/data/serve # ./create_openbsd_vm.sh web03.int.ghetto.sh
        Ghetto.sh OpenBSD VM Creator
    INFO: generating a MAC address...chose 00:de:ad:b9:a5:74
    INFO: Writing seed file: ./00:de:ad:b9:a5:74-install.conf...ok
    INFO: Writing shellscript: ./install_scripts/install-4c0d86cb85931080293280de08eaf70e.sh...ok
    INFO: Choosing the least loaded hypervisor for this vm...chose 192.168.20.102
    INFO: Sending script to remote target: 192.168.20.102...ok
    INFO: Executing script on 192.168.20.102...ok
    INFO: Updating local database...(1 of 1)...ok


Then about 6 minutes later, a the VM created above contacts the REST API and
says it's ready, and gives a few bits of information (ip, uname, etc.)


To Do
-----

  - Write a proper REST API to handle incoming 'registrations' 
  - implement "firstrun" capabilities into the 'checkin.sh' script for installing packages/ports/other post-install configurations
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

Quickstart
----------

lol. Not so quick.

  - Make a Linux box, install KVM, libvirt and virt-install on it
  - Make an OpenBSD box, 
   - make it a DHCP server and 
   - clone this repository into the webroot
   - configure and run ''sync_openbsd_repo.sh'', 
   - Configure tftpd to serve from this directory
   - symlink the wanted pxeboot for the release you just mirrored here. e.g.:
     ''ln -s ./openbsd-mirrors-snapshots-amd64/pxeboot ./auto_install''
   - symlink the wanted bsd.rd for the release you just mirrored here. e.g.:
     ''ln -s ./openbsd-mirrors-snapshots-amd64/bsd.rd ./bsd''
   - Edit the site files in usr/, etc/, and var/ to your liking.
   - Edit and run the ''update_site_file.sh'' script
   - Edit (closely, pay attention to everything down to the libvirt storage pool
     I used; it will likely be different than what you have) the ''create_openbsd_vm.sh'' script
   - Create a keypair, put the public key in root's authorized_keys on the linux box



Description of files
--------------------

My production deployment looks like this:

    root@dnpcor4rtr00:/data/serve # ls -l
    total 156
    drwxr-xr-x  8 root  wheel   512 Feb 27 10:06 .git/
    -rw-r--r--  1 root  wheel   125 Feb 20 15:19 .gitignore
    -rw-r--r--  1 root  wheel   486 Feb 25 03:17 00:de:ad:69:66:17-install.conf
    -rw-r--r--  1 root  wheel   493 Feb 27 10:07 00:de:ad:93:87:d8-install.conf
    -rw-r--r--  1 root  wheel   493 Feb 27 10:07 00:de:ad:b9:a5:74-install.conf
    -rw-r--r--  1 root  wheel   489 Feb 27 00:52 00:de:ad:ba:e1:70-install.conf
    -rw-r--r--  1 root  wheel   493 Feb 27 10:07 00:de:ad:e7:98:dd-install.conf
    -rw-r--r--  1 root  wheel  7260 Feb 27 10:08 README.md
    lrwxr-xr-x  1 root  wheel    40 Jan 28 05:05 auto_install@ -> ./openbsd-mirror-snapshots-amd64/pxeboot
    lrwxr-xr-x  1 root  wheel    39 Jan 28 04:49 bsd@ -> ./openbsd-mirror-snapshots-amd64/bsd.rd
    -rwxr-xr-x  1 root  wheel  9528 Feb 27 10:07 create_openbsd_vm.sh*
    drwxr-xr-x  2 root  wheel   512 Feb 18 22:31 etc/
    -rwxr-xr-x  1 root  wheel  5065 Feb 25 03:38 gcctl*
    drwxr-xr-x  4 root  wheel   512 Feb 27 10:00 ghettoapi/
    -rw-r--r--  1 root  wheel   245 Jan 28 05:15 install.conf
    drwxr-xr-x  2 root  wheel  3584 Feb 25 03:12 install_files/
    drwxr-xr-x  2 root  wheel  2048 Feb 27 10:07 install_scripts/
    drwxr-xr-x  2 root  wheel   512 Jan 30 06:12 openbsd-mirror-5.4-amd64/
    drwxr-xr-x  2 root  wheel  1024 Jan 30 15:12 openbsd-mirror-snapshots-amd64/
    lrwxr-xr-x  1 root  wheel    40 Jan 28 04:49 pxeboot@ -> ./openbsd-mirror-snapshots-amd64/pxeboot
    drwxr-xr-x  8 root  wheel   512 Feb 14 23:02 pxelinux/
    drwxr-xr-x  2 root  wheel   512 Feb 19 02:16 relayd_instances/
    drwx------  3 root  wheel   512 Feb 23 18:11 root/
    drwxr-xr-x  2 root  wheel  4608 Feb 25 03:31 site-backups/
    -rwxr-xr-x  1 root  wheel  2756 Feb  8 16:19 sync_openbsd_repo.sh*
    -rwxr-xr-x  1 root  wheel  2649 Feb 25 03:40 update_site_file.sh*
    drwxr-xr-x  3 root  wheel   512 Jan 30 04:56 usr/
    drwxr-xr-x  3 root  wheel   512 Jan 30 04:54 var/


ghettoapi/*
-----------
the ghettoapi/ directory contains a few important files:

    root@dnpcor4rtr00:/data/serve # tree ghettoapi/
    ghettoapi/
    |-- cgi
    |   |-- checkin                # cgi script that all servers hit when 'checking in'
    |   |-- ghetto.db              # the master database that all scripts update/read from
    |   |-- initialize-db.sh       # a tool to re/initialize the database 
    |   `-- install.conf-old       # a deprecated script, but will still likely be used to auto-generate <mac>-install.conf files in future
    |-- conf
    |   |-- ghettoapi-httpd.conf   # httpd config for this api
    |   `-- mime.types             # httpd complained when it didn't have this file, so here it is.
    `-- start_webserver.sh         # shellscript to start the api.


gcctl
-----
This script is here to parse the sqlite database and provide a clean view of 
what our environment looks like, for example:

    root@dnpcor4rtr00:/data/serve # ./gcctl -c list-vms
    Real Name                         Hostname                    State       IP Address      MAC Address        Root Password  Host Hypervisor
    --------------------------------  --------------------------  ----------  --------------  -----------------  -------------  ---------------
    94018aff143f561c07fe958ae2ebb942  cdist-client.int.ghetto.sh  running     192.168.10.236  00:de:ad:69:66:17  fbead8bd8d54   192.168.20.102 
    9b4582397a4045c9797da63f1b1bae6f  web00.int.ghetto.sh         running     192.168.10.237  00:de:ad:ba:e1:70  34e8f1a9784e   192.168.20.103 
    9011c82a091f5453ae244e9848144895                              in_build                    00:de:ad:93:87:d8  c677d39f7c9b   192.168.20.104 
    eb7575593fecd78d86047053c08761bb                              in_build                    00:de:ad:e7:98:dd  f08758a60e7f   192.168.20.105 
    4c0d86cb85931080293280de08eaf70e                              in_build                    00:de:ad:b9:a5:74  e198539b39c6   192.168.20.102 

and

    root@dnpcor4rtr00:/data/serve # ./gcctl -c list-hypervisors
    Hypervisors
    -----------
    192.168.20.102
    192.168.20.103
    192.168.20.104
    192.168.20.105

another example:

    root@dnpcor4rtr00:/data/serve # ./gcctl -c delete-vm 94018aff143f561c07fe958ae2ebb942
    WARN: removing 94018aff143f561c07fe958ae2ebb942 on 192.168.20.102
    INFO: Destroying the VM...ok
    INFO: Undefining the VM...ok
    INFO: deleting the VM's backing storage...ok
    INFO: Dropping host from database...ok
    INFO: successfully removed 94018aff143f561c07fe958ae2ebb942


    root@dnpcor4rtr00:/data/serve # ./gcctl -c list-vms
    Real Name                         Hostname             State       IP Address      MAC Address        Root Password  Host Hypervisor
    --------------------------------  -------------------  ----------  --------------  -----------------  -------------  ---------------
    9b4582397a4045c9797da63f1b1bae6f  web00.int.ghetto.sh  running     192.168.10.237  00:de:ad:ba:e1:70  34e8f1a9784e   192.168.20.103 
    9011c82a091f5453ae244e9848144895                       in_build                    00:de:ad:93:87:d8  c677d39f7c9b   192.168.20.104 
    eb7575593fecd78d86047053c08761bb                       in_build                    00:de:ad:e7:98:dd  f08758a60e7f   192.168.20.105 
    4c0d86cb85931080293280de08eaf70e                       in_build                    00:de:ad:b9:a5:74  e198539b39c6   192.168.20.102 




MAC-ADDRESS-install.conf
------------------------------
When the OpenBSD VM boots up, autoinstaller will try to hit the next-server on 
port 80 and request this file. It contains answers to the questions you are as-
ked in an interactive openbsd installation. This file is generated on  the fly
by create_openbsd_vm.sh and can be removed/moved after the script completes.


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
