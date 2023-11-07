#!/bin/bash

set -e

fedora_hdd='fedora.qcow2'
fedora_hdd_size='20G'
# the forwarded ssh port used to access the Fedora VM from the host
ssh_port_host=2222
cur_dir=$(pwd)
fedora_iso_base_url='https://dl.fedoraproject.org/pub/fedora/linux/development/39/Everything/aarch64/iso/'
fedora_iso='Fedora-Everything-netinst-aarch64-39.iso'

wipe=''
cdrom=''
vnc=''
graphics='-nographic'
install_vnc_port=''
linux_drives=''

[[ $(uname -a | grep -i darwin) ]] && mac=true && accelerator='hvf' && sudo='sudo'
[[ $(uname -a | grep -i linux) ]] && linux=true && accelerator='kvm' && sudo=''
[[ -z $mac ]] && [[ -z $linux ]] && 'this script only supports only Linux and macos' && exit

if [[ ! $(command -v qemu-system-aarch64) ]]; then
    echo -e "qemu-system-aarch64 doesn't exist\nto install qemu run:"
    [[ $mac = true ]] && echo "brew install qemu" || echo "dnf install qemu-user"
	exit 1
fi

# QEMU_EFI.silent.fd is part of the edk2-aarch64 package on Fedora
[[ $linux = true ]] && bios='/usr/share/edk2/aarch64/QEMU_EFI.silent.fd'
[[ $mac = true ]] && bios='/opt/homebrew/share/qemu/edk2-aarch64-code.fd'

# these are the Linux parttions on the mac that will be mounted by the qemu vm
if [[ $mac = true ]]; then
    linux_drives='
        -drive if=virtio,format=raw,file=/dev/disk0s4
        -drive if=virtio,format=raw,file=/dev/disk0s5
        -drive if=virtio,format=raw,file=/dev/disk0s6
        '
fi

qemu_pid=$(pgrep -f "hostfwd=tcp::$ssh_port_host-:22" || true)

while [ $# -gt 0 ]
do
    case $1 in
    -c|--cdrom) cdrom="-cdrom $fedora_iso";;
    -g|--graphics) graphics='';;
    -k|--kill) $sudo kill -9 $qemu_pid; exit;;
    -w|--wipe) wipe=true;;
    -v|--vnc) vnc='-vnc :0 -monitor stdio'; graphics='';;
    (*) break;;
    esac
    shift
done

if [[ -n $qemu_pid ]]; then
    echo 'This Fedora VM is already running'
    echo "if you're not able to access it to shut it down, you can kill it with:"
    echo './script-qemu.sh --kill'
    exit 1
fi

if [[ -n $cdrom ]] && [[ ! -f $fedora_iso ]]; then
    # discovers the most recent version of $fedora_iso_base*.iso, where
    # $fedora_iso_base is $fedora_iso with .iso stripped.
    # e.g. if fedora_iso_base == Fedora-Everything-netinst-aarch64-39.iso,
    # it discovers the most recent Fedora-Everything-netinst-aarch64-39*.iso
    fedora_iso_image=$(curl $fedora_iso_base_url 2> /dev/null | grep $(basename -s .iso $fedora_iso) | sed -E 's|.*<a.*>\s*(.*)\s*</a>.*|\1|g' | grep -v manifest | sort -Vr | head -n 1)
    if [[ $fedora_iso_image == '' ]]; then
        echo 'Could not find a suitable version of the Fedora installer ISO.'
        exit 1
    fi
    wget "${fedora_iso_base_url}${fedora_iso_image}" -O $fedora_iso
fi

# you only need to forward port 5901 when using the installer iso
[[ -n $cdrom ]] && install_vnc_port=',hostfwd=tcp::5901-:5901'

# specify the -w|--wipe arg to remove fedora.qcow2 hdd and create a new one
[[ $wipe = true ]] && [[ -f $fedora_hdd ]] && rm -f $fedora_hdd

# if fedora.qcow2 does not exist -- then create a new one with size specified by $fedora_hdd_size
[[ ! -f $fedora_hdd ]] && qemu-img create -f qcow2 $fedora_hdd $fedora_hdd_size

# notes:
# ctrl+a, release, then x to exit a qemu session (better to shutdown the proper way though)

# if you enable the  -v|--vnc option you need to to connect a vnc client to port :5900

$sudo qemu-system-aarch64 \
    -machine virt \
    -accel $accelerator \
    -cpu host \
    -smp 4 \
    -m 2048M \
    -bios $bios \
    $graphics \
    $cdrom \
    $vnc \
    -drive file=$fedora_hdd,format=qcow2,if=virtio,cache=writethrough \
    -device virtio-net-pci,netdev=mynet0 \
    -netdev user,id=mynet0,hostfwd=tcp::$ssh_port_host-:22$install_vnc_port \
    -fsdev local,id=cur_dir_dev,path=$cur_dir,security_model=mapped-xattr \
    -device virtio-9p-pci,fsdev=cur_dir_dev,mount_tag=local_mnt \
    $linux_drives \

# rhe reason that port 5901 is being forwarded is for new installs. When you boot from the iso
# if you select the option to Start VNC -- then you'll be able to connect to it on port :5901
