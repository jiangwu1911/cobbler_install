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
