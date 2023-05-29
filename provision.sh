#!/bin/bash

DC_PREFIX="infra"
STORAGE_PATH="/infra-data/"${DC_PREFIX}
IP="192.168.0"
IFACE="eth0"
GATEWAY_IP=${IP}".1"
GATEWAY=${GATEWAY_IP}"/24"
DC_POOL=${DC_PREFIX}"-pool"
DC_PROFILE_NAME=${DC_PREFIX}"-profile"
DC_BRIDGE_NAME=${DC_PREFIX}"-br"

OS="images:ubuntu/jammy"
NEST_DC=${DC_PREFIX}"-nested"


if ! [[ $(cat /etc/subuid /etc/subgid | grep -o -i root | wc -l) -eq 2 ]]; then
  sudo sed -i '/^root:/d' /etc/subuid /etc/subgid
  sudo bash -c 'echo "root:500000:196608" >> /etc/subuid'
  sudo bash -c 'echo "root:500000:196608" >> /etc/subgid'

  systemctl stop snap.lxd.daemon
  systemctl start snap.lxd.daemon
  systemctl status snap.lxd.daemon
fi 
# check if jq exists
if ! snap list | grep jq >>/dev/null 2>&1; then
  sudo snap install jq 
fi
# check if lxd exists
if ! snap list | grep lxd >>/dev/null 2>&1; then
  sudo snap install lxd 
fi

if ! [ -d ${STORAGE_PATH} ]; then
    sudo mkdir -p ${STORAGE_PATH}
fi

# creating the pool
lxc storage create ${DC_POOL} dir source=${STORAGE_PATH}

#create network bridge
lxc network create ${DC_BRIDGE_NAME} ipv6.address=none ipv4.address=${GATEWAY} ipv4.nat=true

# creating needed profile
lxc profile create ${DC_PROFILE_NAME}

# editing needed profile
echo "config:
raw.lxc: |
  lxc.apparmor.profile = generated
  lxc.apparmor.allow_nesting = 1
  lxc.cgroup.devices.allow=a
  lxc.mount.auto=proc:rw sys:rw
devices:
  ${IFACE}:
    name: ${IFACE}
    network: ${DC_BRIDGE_NAME}
    type: nic
  root:
    path: /
    pool: ${DC_POOL}
    type: disk
name: ${DC_PROFILE_NAME}" | lxc profile edit ${DC_PROFILE_NAME} 

#create nested data-centre container
lxc init ${OS} ${NEST_DC} --profile ${DC_PROFILE_NAME}
lxc network attach ${DC_BRIDGE_NAME} ${NEST_DC} ${IFACE}
lxc config device set ${NEST_DC} ${IFACE} ipv4.address ${IP}.2

sudo lxc config device add ${NEST_DC} ${NEST_DC}-DC-share disk source=${PWD}/infra-scripts/ path=/workdir
sudo lxc config set ${NEST_DC} security.nesting=true security.syscalls.intercept.mknod=true security.syscalls.intercept.setxattr=true
lxc config set ${NEST_DC} raw.idmap "both ${UID} ${UID}"
lxc start ${NEST_DC} 

sudo lxc exec ${NEST_DC} -- /bin/bash /workdir/${NEST_DC}.sh








