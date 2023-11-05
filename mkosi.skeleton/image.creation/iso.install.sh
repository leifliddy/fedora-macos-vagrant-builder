#!/bin/bash

# this script isn't used at the moment -- but may be used in the future.

mkdir -p /local_mnt && echo 'local_mnt /local_mnt 9p trans=virtio,version=9p2000.L 0 0' >> /etc/fstab && systemctl daemon-reload && mount -a

hostnamectl set-hostname fedora-qemu
rm -f /root/anaconda-ks.cfg
rm -rf /lost+found
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl reload sshd
dnf -y install arch-install-scripts bash-completion net-tools vim-enhanced wget which
echo "alias vi='vim'" >> /root/.bashrc
source /root/.bashrc
cp /local_mnt/files/{chroot.asahi,umount.asahi} /usr/local/sbin
chmod 755 /usr/local/sbin/{chroot.asahi,umount.asahi}

# beautify /etc/fstab
fstab=$(cat /etc/fstab)
comments=$(echo "$fstab" | grep '^#')
entries=$(echo "$fstab" | grep -v '^#' | column -t)
# do we want to preserve the comments?
# fstab_new=$(echo "$comments" && echo "$entries")
echo "$entries" > /etc/fstab
systemctl daemon-reload
