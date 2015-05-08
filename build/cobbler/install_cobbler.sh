#!/bin/bash

PASSWORD='abc123'

function get_input() {
    read -p "$1 (default: $2): " VAR
    if [ -z $VAR ]; then
        VAR=$2
    fi
    eval $3=$VAR
}

function answer_yes_or_no() {
    while :
    do
        read -p "$1 (yes/no): " VAR
        if [ "$VAR" = "yes" -o "$VAR" = "no" ]; then
            break
        fi
    done
    eval $2=$VAR
}

function splash_screen() {
    clear
    echo -e "\n            Install cobbler\n"
}

function config_network() {
    yum install -y net-tools
    while :
    do
        splash_screen

        echo -e "Config network:\n"
        default_interface=$(ip link show  | grep -v '^\s' | cut -d':' -f2 | sed 's/ //g' | grep -v lo | head -1)
        address=$(ip addr show label $default_interface scope global | awk '$1 == "inet" { print $2,$4}')
        ip=$(echo $address | awk '{print $1 }')
        ip=${ip%%/*}
        broadcast=$(echo $address | awk '{print $2 }')
        netmask=$(route -n |grep 'U[ \t]' | grep -v 169.254 | head -n 1 | awk '{print $3}')
        gateway=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
        hostname=`hostname`
        dns=$(cat /etc/resolv.conf | grep nameserver | head -n 1 | awk '{print $2}')

        get_input 'Input hostname' $hostname HOSTNAME
        get_input 'The NIC name for PXE install' $default_interface INTERFACE
        get_input 'IP address' $ip IPADDR
        get_input 'Netmask' $netmask NETMASK
        get_input 'Gateway' $gateway GATEWAY
        SUBNET=$(echo $IPADDR | cut -d. -f1-3)'.0'
        dhcp_start=$(echo $IPADDR | cut -d. -f1-3)'.100'
        dhcp_end=$(echo $IPADDR | cut -d. -f1-3)'.254'
        get_input 'DHCP range start' $dhcp_start DHCP_START
        get_input 'DHCP range end' $dhcp_end DHCP_END
        get_input 'DNS server' $dns DNS_SERVER

        echo -e "\nNetwork parameters:"
        echo "    Hostname: $HOSTNAME"
        echo "    IP address: $IPADDR"
        echo "    Netmask: $NETMASK"
        echo "    Gateway: $GATEWAY"
        echo "    DHCP range start: $DHCP_START"
        echo "    DHCP range end: $DHCP_END\n"
        echo -e "    DNS server: $DNS_SERVER\n"

        answer_yes_or_no "is it correct:" ANSWER
        if [ "$ANSWER" = "yes" ]; then
            break
        fi
    done

    cat > /etc/sysconfig/network-scripts/ifcfg-$INTERFACE <<EOF
DEVICE="$INTERFACE"
BOOTPROTO="static"
GATEWAY="$GATEWAY"
IPADDR="$IPADDR"
NETMASK="$NETMASK"
ONBOOT="yes"
DNS1="$DNS_SERVER"
EOF
    cat > /etc/hostname <<EOF
$HOSTNAME
EOF
    service network restart
}

function install_cobbler() {
    yum install -y cobbler cobbler-web ntp ntpdate dhcp
}

function config_yum_repo() {
    cat > /etc/yum.repos.d/centos.repo <<EOF
[base]  
name=CentOS-$releasever - Base  
baseurl=http://mirrors.sohu.com/centos/7/os/x86_64/  
gpgcheck=0  
enabled=1  
  
[epel]  
name=epel  
baseurl=http://mirrors.sohu.com/fedora-epel/7/x86_64/  
gpgcheck=0  
enabled=1    

[extra]  
name=extra  
baseurl=http://mirrors.sohu.com/centos/7/extras/x86_64  
gpgcheck=0  
enabled=1  
  
[update]  
name=extra  
baseurl=http://mirrors.sohu.com/centos/7/updates/x86_64  
gpgcheck=0  
enabled=1 
EOF
    yum clean all
}

function config_cobbler() {
    cp /etc/cobbler/settings /etc/cobbler/settings.bak
    cp /etc/cobbler/dhcp.template /etc/cobbler/dhcp.template.bak

    mkdir -p /var/lib/cobbler/loaders
    cp loaders/* /var/lib/cobbler/loaders

    encrypted_password=`openssl passwd -1 -salt 'a%fiw#ewr' $PASSWORD`
    sed -i "s/^default_password_crypted.*/default_password_crypted: \"$encrypted_password\"/" /etc/cobbler/settings

    sed -i "s/^server: 127.0.0.1/server: $IPADDR/" /etc/cobbler/settings
    sed -i "s/^next_server: 127.0.0.1/next_server: $IPADDR/" /etc/cobbler/settings
    sed -i "s/manage_dhcp: 0/manage_dhcp: 1/" /etc/cobbler/settings

    sed -i "s/disable.*= yes/disable = no/" /etc/xinetd.d/tftp
    sed -i "s/disable.*= yes/disable = no/" /etc/xinetd.d/rsync

    sed -i "s#^subnet.*#subnet $SUBNET netmask $NETMASK {#" /etc/cobbler/dhcp.template
    sed -i "s/option routers.*192.168.*/option routers $GATEWAY;/" /etc/cobbler/dhcp.template
    sed -i "/option domain-name-servers.*192.168.*/d" /etc/cobbler/dhcp.template
    sed -i "s/option subnet-mask.*255.255.255.0.*/option subnet-mask $NETMASK;/" /etc/cobbler/dhcp.template
    sed -i "s/range dynamic-bootp.*192.168.*/range dynamic-bootp $DHCP_START $DHCP_END;/" /etc/cobbler/dhcp.template
}

function start_cobbler() {
    service cobblerd restart
    service xinetd restart
    service httpd start
    cobbler sync

    chkconfig cobblerd on
    chkconfig xinetd on
    chkconfig httpd on
}

function generate_sshkey() {
    mkdir -p /root/.ssh
    rm -rf /root/.ssh/*
    ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
    cat >> /root/.ssh/config <<EOF
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
EOF
}


config_network
#config_yum_repo

install_cobbler
config_cobbler
start_cobbler

generate_sshkey
