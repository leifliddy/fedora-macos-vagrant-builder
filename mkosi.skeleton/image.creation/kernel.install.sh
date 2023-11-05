#!/bin/bash

# this script only needs to run during the image creation process

export KERNEL_INSTALL_MACHINE_ID=$(cat /etc/machine-id)

rm -f /boot/loader/entries/*.conf

kernel_version=$(rpm -q kernel | sed 's/kernel-//')

kernel-install add $kernel_version /lib/modules/$kernel_version/vmlinuz
