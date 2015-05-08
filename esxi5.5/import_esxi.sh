#!/bin/bash

mkdir esxi55
mount -o loop VMware-VMvisor-Installer-201410001-2143827.x86_64.iso esxi55
current_dir=`pwd`
cobbler import --path=${current_dir}/esxi55 --name=esxi55

cp esxi55.ks /var/lib/cobbler/kickstarts/
umount esxi55
rm -rf esxi55

cobbler profile edit --name=esxi55-x86_64 --distro=esxi55-x86_64 --kickstart=/var/lib/cobbler/kickstarts/esxi55.ks

cobbler sync
