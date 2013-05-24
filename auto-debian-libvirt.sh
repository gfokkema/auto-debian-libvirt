#!/bin/sh

RAM=512 # RAM in MiB
SIZE=5 # HD size in GiB
VMS_DIRECTORY=/VMS # Directory to allocate VM image file
RELEASE=wheezy # Debian release to install
ARCH=amd64 # Architecture
MIRROR=http://ftp.debian.org/debian # Debian mirror
PRESEED=https://github.com/albertomolina/auto-debian-libvirt/blob/master/wheezy-preseed.txt
VIRTUALNETWORK=default # Virtual network

if [  $# -ne 1 ]
then
echo "Usage: $0 guest-name"
exit 1
fi
 
virt-install \
--connect=qemu:///system \
--name=${1} \
--ram=$RAM \
--vcpus=1 \
-f $VMS_DIRECTORY/${1}.img \
-s $SIZE \
-l $MIRROR/dists/$RELEASE/main/installer-$ARCH/ \
--os-type=linux \
--os-variant=debian$RELEASE \
--virt-type=kvm \
--network network:$VIRTUALNETWORK \
--extra-args="auto=true priority=critical hostname=${1} domain=example.com preseed/url=$PRESEED"