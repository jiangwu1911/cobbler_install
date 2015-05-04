#!/bin/bash

#mkdir centos7
#mount -o loop CentOS-7-x86_64-Minimal-1503-01.iso centos7
#current_dir=`pwd`
#cobbler import --path=${current_dir}/centos7 --name=centos7 --arch=x86_64

cp centos7.ks /var/lib/cobbler/kickstarts/
#umount centos7
#rm -rf centos7

sshkey=`cat /root/.ssh/id_rsa.pub`
cobbler_ip=`ifconfig | grep -v 127.0.0.1 | grep inet | grep -v inet6 | awk '{print $2}' | sed 's/addr://'`
sed -i "s#ssh-rsa.*#$sshkey#" centos7.ks
sed -i "s#10\.0\.10\.10#$cobbler_ip#" /var/lib/cobbler/kickstarts/centos7.ks
cobbler profile edit --name=centos7-x86_64 --distro=centos7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos7.ks

cobbler sync
