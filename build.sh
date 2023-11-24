#!/bin/bash

set -e

mnt_image="$(pwd)/mnt_image"
mkosi_output='mkosi.output'
disk_raw="$mkosi_output/fedora.raw"

if [ "$(whoami)" != 'root' ]; then
    echo "You must be root to run this script."
    exit 1
fi


[ ! -d $mnt_image ] && mkdir $mnt_image
[ ! -d mkosi.cache ] && mkdir mkosi.cache
[ ! -d mkosi.output ] && mkdir mkosi.output
[ ! -d mnt_image ] && mkdir mnt_image


usage=$(echo -e "Usage $(basename "$0") [OPTION]\n
  -c, --compress    compress the fedora.qcow2 image\n
      --help        display this help and exit\n
")


# to compress the fedora.qcow2 image
# don't use this options if the goal is to create a vagrant box
# as the resulting vagrant box will mysteriously ens up being larger in size (you read that right)

while [ $# -gt 0 ]
do
    case $1 in
        --help) echo "$usage"; exit;;
        -c|--compress) compress='-c ';;
        (*) break;;
    esac
    shift
done

mkosi_create_rootfs() {
    umount_image
    mkosi clean
    mkosi
}

mount_image() {
    umount_image silent# mounts mkosi.rootfs.raw from mnt_image/
    echo '### Mounting image partitions'
    kpartx -a $disk_raw
    get_partition_devices
    [[ -z "$(findmnt -n $mnt_image)" ]] && mount $root_part $mnt_image
    [[ -z "$(findmnt -n $mnt_image/efi)" ]] && mount $efi_part $mnt_image/efi
    [[ -z "$(findmnt -n $mnt_image/boot)" ]] && mount $boot_part $mnt_image/boot
    systemctl daemon-reload
}

umount_image() {
    set +e
    # unmounts mkosi.rootfs.raw from mnt_image/
    [[ $1 != 'silent' ]] && echo '### Unmounting image partitions'
    [[ "$(findmnt -n $mnt_image/efi)" ]] && umount $mnt_image/efi
    [[ "$(findmnt -n $mnt_image/boot)" ]] && umount $mnt_image/boot
    [[ "$(findmnt -n $mnt_image)" ]] && umount $mnt_image
    [[ -f $disk_raw ]] && [[ -n "$(kpartx -l $disk_raw)" ]] && kpartx -d $disk_raw
    set -e
}

get_partition_devices() {
    loop_devices=$(kpartx -l $disk_raw | awk '{print $1}')
    efi_loopdev=$(echo "$loop_devices" | grep 'p1$')
    boot_loopdev=$(echo "$loop_devices" | grep 'p2$')
    root_loopdev=$(echo "$loop_devices" | grep 'p3$')

    efi_part="/dev/mapper/$efi_loopdev"
    boot_part="/dev/mapper/$boot_loopdev"
    root_part="/dev/mapper/$root_loopdev"
}

# ./build.sh mount (mounts mkosi.output/fedora.raw to mnt_image)
#  or
# ./build.sh umount (unmounts mkosi.output/fedora.raw from mnt_image)
# or
# ./build.sh chroot (mounts mkosi.output/fedora.raw to mnt_image and then arch-chroot's into it)

if [[ $1 == 'mount' ]]; then
    mount_image
    exit
elif [[ $1 == 'umount' ]] || [[ $1 == 'unmount' ]]; then
    umount_image
    exit
elif [[ $1 == 'remount' ]]; then
    umount_image
    mount_image
    exit
elif [[ $1 == 'chroot' ]]; then
    mount_image
    echo "### Chrooting into $mnt_image"
    arch-chroot $mnt_image
    exit
elif [[ -n $1 ]]; then
    echo "$1 isn't a recogized option"
    exit
fi


make_image() {
    # if  $mnt_image is unmounted, then mount it
    mount_image
    echo "### Setting uuid's in /etc/fstab"

    efi_uuid=$(blkid -s UUID -o value $efi_part)
    boot_uuid=$(blkid -s UUID -o value $boot_part)
    root_uuid=$(blkid -s UUID -o value $root_part)

    sed -i "s/EFI_UUID_PLACEHOLDER/$efi_uuid/" $mnt_image/etc/fstab
    sed -i "s/BOOT_UUID_PLACEHOLDER/$boot_uuid/" $mnt_image/etc/fstab
    sed -i "s/ROOT_UUID_PLACEHOLDER/$root_uuid/" $mnt_image/etc/fstab
    sed -i "s/ROOT_UUID_PLACEHOLDER/$root_uuid/" $mnt_image/etc/kernel/cmdline
    systemctl daemon-reload

    #need to generate a machine-id so that we can run kernel-install
    echo -e '\n### Generating a new machine-id'
    rm -f $mnt_image/etc/machine-id
    chroot $mnt_image dbus-uuidgen --ensure=/etc/machine-id
    chroot $mnt_image echo "KERNEL_INSTALL_MACHINE_ID=$(cat $mnt_image/etc/machine-id)" > $mnt_image/etc/machine-info

    echo -e '\n### Generating GRUB config'
    sed -i "s/BOOT_UUID_PLACEHOLDER/$boot_uuid/" $mnt_image/boot/efi/EFI/fedora/grub.cfg
    arch-chroot $mnt_image grub2-mkconfig -o /boot/grub2/grub.cfg

    # run kernel-install
    echo '### Running kernel-install'
    arch-chroot $mnt_image /image.creation/kernel.install.sh

    # add vim alias to root bashrc
    echo "alias vi='vim'" >> /root/.bashrc

    ###### post-install cleanup ######
    echo -e '\n### Cleanup'
    rm -rf $mnt_image/lost+found/
    rm -rf $mnt_image/boot/lost+found/
    rm -f  $mnt_image/etc/dracut.conf.d/initial-boot.conf
    rm -rf $mnt_image/image.creation
    rm -f  $mnt_image/init
    rm -f  $mnt_image/var/lib/systemd/random-seed
    sed -i '/GRUB_DISABLE_OS_PROBER=true/d' $mnt_image/etc/default/grub

    # not sure how/why a mnt_image/root/fedora-macos-asahi-qemu directory is being created
    # remove it like this to account for it being named something different
    find $mnt_image/root/ -maxdepth 1 -mindepth 1 -type d | grep -Ev '/\..*$' | xargs rm -rf
    umount_image

    echo "### Converting $mkosi_output/fedora.raw to qemu/fedora.qcow2"
    [[ -f $mkosi_output/fedora.raw ]] && qemu-img convert -f raw -O qcow2 $compress $mkosi_output/fedora.raw qemu/fedora.qcow2
    echo -e '\n### To run the image with qemu:'
    echo 'cd qemu && ./script-qemu.sh'

    echo -e '\n### To create a vagrant box from the image:'
    echo 'cd vagrant && ./script-vagrant.sh'
    echo -e '\n### Done'
}

if [[ $(command -v getenforce) ]] && [[ "$(getenforce)" = "Enforcing" ]]; then
    setenforce 0
    trap 'setenforce 1; exit;' EXIT SIGHUP SIGINT SIGTERM SIGQUIT SIGABRT
fi

mkosi_create_rootfs
make_image
