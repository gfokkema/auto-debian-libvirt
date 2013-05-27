# Auto Debian Libvirt

Shell script for automatic provision of debian virtual machines on libvirt (kvm)

## Prerequisites

* kvm and libvirt installed on host
* user must belong to libvirt group

## Configuration

Preseed file is provided with spanish configuration, please download it and change 
the following parameters if needed:

d-i debian-installer/locale string es_ES.UTF-8
d-i console-keymaps-at/keymap select es
d-i keyboard-configuration/xkb-keymap select es
d-i time/zone string Europe/Madrid

Once wheezy-pressed.txt is adjusted, upload it to a web server and set the PRESEED
parameter of auto-debian-libvirt.sh

WARNING: preseed file must be available through http, not https

Virtual machine specifications can be adapted to your specific needs setting the 
parameters RAM, SIZE, etc.

## Using de virtual machine

| User | Password |
| ---- | --------:|
| root | root |
| user | user |
