#!/bin/sh

VMS_DIRECTORY=/data # Directory to allocate VM image file
MIRROR=http://ftp.nl.debian.org/debian # Debian mirror
#PRESEED=http://app.gntel.nl/debian.preseed
PRESEED=http://aptmirror.gntel.nl/stretch-preseed.txt

if [  $# -lt 3 ]; then
  echo "Usage: ${0} (d1|d2|tcn|zb) guest-name bridge-if [ vcpus [ ram [ size ] ] ]"
  exit 1
fi

case ${1} in
  zb)
    HOST=172.19.5.31
    ;;
  d1)
    HOST=172.19.1.31
    ;;
  d2)
    HOST=172.19.1.32
    ;;
  tcn)
    HOST=172.19.3.31
    ;;
  *)
    echo "Invalid host ${1}. Choose one of (d1|d2|tcn|zb)."
    exit 1
    ;;
esac

NAME=${2}
BRIDGEIF=${3}
VCPUS=${4:-1}
RAM=${5:-512} # RAM in MiB
SIZE=${6:-50} # HD size in GiB
RELEASE=stretch # Debian release to install
ARCH=amd64 # Architecture

VARIANT=wheezy # Libvirt os-variant, does not have stretch yet
DISK="${VMS_DIRECTORY}/${NAME}/root.img"
REMOTE="ssh ${HOST}"
VIRSHCON="--connect=qemu+ssh://${HOST}/system"

# Do not continue when the vm exists already
echo Looking up potential duplicates...
if virsh ${VIRSHCON} list --all --name | grep -P "^${NAME}$" > /dev/null 2>&1; then
  echo "Domain ${NAME} already exists."
  exit 1
fi

# Do not continue when the disk exists already
if $REMOTE "[[ -e ${DISK} ]]"; then
  echo ${DISK} already exists, exiting...
  exit 1
fi

# Check $VCPUS for sensible values (ie: less than # proc / 2)
echo Checking number of cpu\'s...
if $REMOTE "[ ${VCPUS} -ge \$((\$(nproc) / 2)) ]"; then
  echo "Please use less cpu's than ${VCPUS}."
  exit 1
fi

# Check whether BRIDGEIF is a valid interface on $REMOTE
echo Looking up interface ${BRIDGEIF}...
if ! $REMOTE "ip link show ${BRIDGEIF} 2> /dev/null"; then
  echo "Interface ${BRIDGEIF} does not exist."
  exit 1
fi

# INPUT #
echo Enter the ip address of ${NAME}:
read ip
if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo Invalid ip ${ip} entered.
  exit 1
fi

# Do not continue when the ip address is taken already
if ping -c1 $ip -W1 >/dev/null; then
  echo Ip address $ip already in use. Refusing to continue.
  exit 1
fi

# Do not continue when there's no dns record
if [[ "$(dig -x $ip +short)" == "ip-space-by.gntel.nl." ]]; then
  echo There\'s no DNS record for $ip. Please create one and try again.
  exit 1
fi

echo Mask:
read mask
if ! [[ $mask =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo Invalid mask ${mask} entered.
  exit 1
fi
 
echo Gateway:
read gw
if ! [[ $gw =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo Invalid gateway ${gw} entered.
  exit 1
fi

dns=194.140.246.83

echo
echo "I will start creating domain ${NAME} with the following specs:"
echo "Hardware:"
echo "  cpus:     ${VCPUS}"
echo "  ram:      ${RAM} MB"
echo "Networking:"
echo "  bridgeif: ${BRIDGEIF}"
echo "  ip:       ${ip}"
echo "  mask:     ${mask}"
echo "  gw:       ${gw}"
echo "  dns:      ${dns}"
echo "Disk and OS:"
echo "  path:     ${DISK}"
echo "  size:     ${SIZE} GB"
echo "  os:       ${RELEASE}"
echo
echo "Shall I continue? (yes/no)"
read answer

[[ $answer =~ ^y(|es)$ ]] || exit 0

${REMOTE} "[[ -d \$(dirname ${DISK}) ]] || sudo mkdir -p \$(dirname ${DISK})"

echo Creating domain ${NAME}...
virt-install \
${VIRSHCON} \
--name=${NAME} \
--vcpus=${VCPUS} \
--ram=${RAM} \
-f ${DISK} \
-s ${SIZE} \
-l ${MIRROR}/dists/${RELEASE}/main/installer-${ARCH}/ \
--os-type=linux \
--os-variant=debian${VARIANT} \
--virt-type=kvm \
--network=bridge:${BRIDGEIF},model=virtio \
--extra-args="auto=true priority=critical
hostname=${NAME} domain=gntel.nl
netcfg/disable_dhcp=true netcfg/confirm_static=true
netcfg/get_ipaddress=${ip}
netcfg/get_netmask=${mask}
netcfg/get_gateway=${gw}
netcfg/get_nameservers=${dns}
preseed/url=${PRESEED}"
