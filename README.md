OpenBSD Cloud
-------------

Pre Requisites
--------------

  * 1 or more Linux boxes with libvirt,virt-install installed
  * at least one OpenBSD machine serving as at least a DHCP server with at least 1GB of storage

This directory represents a few things:

  * the tftpboot directory hosted from a next-server
  * The webroot hosted from that same next-server
  * A place to run your vm creation scripts from
  * This directory must be available from http as well

Description of files
--------------------

00:b0:0b:89:a0:8c-install.conf
------------------------------
When the OpenBSD VM boots up, autoinstaller will try to hit the next-server on port 80 and request this file.
It contains answers to the questions you are asked in an interactive openbsd installation. This file is gene-
rated on  the fly by create_openbsd_vm.sh.

README.md
---------
The readme, this file.

auto_install
------------
The PXE loader need to be linked/coped to this file, I forgot why, but I believe it's to differentiate betwe-
en an auto-install and an auto-upgrade.

auto_install -> ./openbsd-mirror-snapshots-amd64/pxeboot
pxeboot -> ./openbsd-mirror-snapshots-amd64/pxeboot

bsd
---
The 'bsd' file is the 'kernel' that is sent by the pxe loader. It's a ramdisk containing the installation im-
age. In my case, it's a symlink to the bsd.rd of the distribution I want to boot by default:

bsd -> ./openbsd-mirror-snapshots-amd64/bsd.rd

etc/ usr/ var/
--------------
These directories are used as both the ramdisk configuration (only /etc/boot.conf) and site configuration.

install.conf
------------
A default install.conf, in case the auto-installer can't find <mac>-install.conf

install_scripts
---------------
This is where the 'build it' scripts go to. Prior to building a VM, the script to actually built it is staged
here. Then it is scp'd over to the destination (a random host) and run. You can use this directory to rebuild
or troubleshoot a failed build.

openbsd-mirror-version-arch
----------------
These are the mirrored directories of public mirrors. We'll pull the install media off of these directories.

pxeboot
-------
Symlink to the particular distribution's pxeboot file. This is required to pxeboot openbsd VMs.

site-backups
------------
When a new site${version}.tgz file is made, the old one is backed up here.

create_openbsd_vm.sh
--------------------
This script is the one that actually creates the VMs on the remote (randomly selected) hosts. It stages up a
shellscript in ./install_scripts, scp's it over to the target, then runs it over there. Reliable, simple, not
pretty, but it works. 

sync_openbsd_repo.sh
--------------------
This script creates a series of directories called openbsd-mirror-${VERSION}-${ARCH} and contains the same 
directories you would see on an official openbsd mirror. We need this because we don't want to rape a mirror
every time we want to build a box. Your newly built VMs will build themselves using these files.

update_site_file.sh
-------------------
Creates a new site${version}.tgz file, and backs up the old one to ./site-backups. The script also ensures the
index.txt is up-to-date. The site${version}.tgz file goes with the rest of the distribution sets.

