install
text
auth --enableshadow --passalgo=sha512
ignoredisk --only-use=sda

lang en_US.UTF-8
keyboard us
timezone Asia/Shanghai
selinux --disabled
firewall --disabled
services --enabled=NetworkManager,sshd
reboot

bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype xfs --size=200
part pv.01 --size=1 --grow
volgroup rootvg01 pv.01
logvol / --fstype xfs --name=lv01 --vgname=rootvg01 --size=1 --grow
 
rootpw --iscrypted $6$XmAncpkAdpDoR5bO$.FI0THeFcxkxxIvXKr3HNh5gYdk1P2WJA9XfM1XOm3b18MpwWrjL9TNqWAFk7CrgwfKeaZd0CEX6UddBUr9CT.

repo --name=base --baseurl=http://10.0.10.10/cobbler/ks_mirror/centos7-x86_64/
url --url="http://10.0.10.10/cobbler/ks_mirror/centos7-x86_64/"

%pre
$SNIPPET('pre_install_network_config')
%end
 
%packages --nobase --ignoremissing
@core
%end

%post 
$SNIPPET('post_install_network_config')

# Config yum repo
rm -f /etc/yum.repos.d/*
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
EOF

# Config ssh key
cd /root
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmOAp18/6mjSRcW8UZySU7EGoe2OJ17VR5GMGMOtUBCe0gNQF7jYsXeBNaXlSCkTNKme4svnqIve/fR9aX3msuE5/ankscHUri+SN4ibQuLosyMN1HYZlOYxEDQs3h+CxJ27PR19q4Uj9QvkLBqMp9LNA1jywpOVcqweDRI5C1VU0IbM7OOn/hAJgdQpUQu4uz2l504WBojrf8F9CpW5wzjT5c1T5ibRUVRKNTMu0ELF964rLDTdszaxx7Zr33tUDySBBwiz523PCctk4Bab+to98CCfR7ndU8f63f/GSZTtvqqhGYMGtbVr32PzWKBqmAow+fEv7JXXkurcgGS8Ml root@cobbler
PUBLIC_KEY

chmod 600 .ssh/authorized_keys

cat >> .ssh/config <<EOF
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
EOF

%end
