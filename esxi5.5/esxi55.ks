vmaccepteula
rootpw --iscrypted $6$sGfS0xYy$jtt3uhjfZ1rfCS7LNK3SzC7zSlL/zcXMpF9mxEvTTEDTcLhMLFbJpm4.YtMjRSTcxjz0jK7jUpgP6Q4J4s0yZ.
install --firstdisk --overwritevmfs
reboot

$SNIPPET('network_config')

%pre --interpreter=busybox

$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')

%post --interpreter=busybox

$SNIPPET('kickstart_done')

# Enable ssh
%firstboot --interpreter=busybox

# Assign license
vim-cmd vimsvc/license --set 4A2XT-00004-7ZUZ1-8L97K-ACJL7

# Enable ssh
vim-cmd hostsvc/enable_ssh
vim-cmd hostsvc/start_ssh

# FirewallRules for VNC console
cat > /etc/vmware/firewall/vnc.xml <<EOF
<!-- FirewallRule for VNC Console -->
<ConfigRoot>
<service>
<id>VNC</id>
<rule id = '0000'>
<direction>inbound</direction>
<protocol>tcp</protocol>
<porttype>dst</porttype>
<port>
<begin>5900</begin>
<end>6010</end>
</port>
</rule>
<rule id = '0001'>
<direction>outbound</direction>
<protocol>tcp</protocol>
<porttype>dst</porttype>
<port>
<begin>0</begin>
<end>65535</end>
</port>
</rule>
<enabled>true</enabled>
<required>false</required>
</service>
</ConfigRoot>
EOF
esxcli network firewall refresh
