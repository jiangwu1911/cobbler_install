#!/bin/bash

cp -f boot.cfg /var/lib/tftpboot

cobbler system remove --name=esx04

cobbler system add --name=esx04 --hostname=esx04 --profile=esxi55-x86_64 --mac='00:50:56:37:1C:93' --interface=vmnic0 --ip-address='192.168.206.143' --netmask='255.255.255.0' --gateway='192.168.206.2' --name-servers='192.168.206.2' --static=1 
