# Fedora qemu Asahi image
Builds and runs minimal Fedora qemu image  

Can be used to rescue a Fedora Asahi Linux system  

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/293087dd-384b-4566-a4c2-6431596f7c31" width=65%>
<br/>
<br/>

The image can be built via `mkosi` or via booting and installing via an `iso` image

## Building the image on Fedora
This image needs to currently be built on a ```Fedora 39``` system (```aarch64``` or ```x86_64``` should both work)  
## Fedora Package Install 
```dnf install arch-install-scripts bubblewrap qemu-system-aarch64```

## macos Package Install

### Notes
- The root password is **fedora**If the event that you make changes to the raw image in this manner

- Once the VM is running you can connect to it via ssh port 2222 ie ```ssh -l root -p 2222 m1```  
```qemu-user-static``` is needed if building the image on a ```non-aarch64``` system  
- Building the image on a **Fedora 39** system currently requires that you install `mkosi` from main:  
  `python3 -m pip install --user git+https://github.com/systemd/mkosi.git`

## To build the image via `mkosi`
```
# build on a Fedora 39 system
./build
# this will create the following images:
1. mkosi.output/fedora.raw
2. qemu/fedora.qcow2 (this is simply a compressed verion of fedora.raw that's used with qemu)
```

## To mount/umount/chroot the fedora.raw image  
```
./build {mount, umount, chroot}<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/293087dd-384b-4566-a4c2-6431596f7c31)" width=65%>

This is in incredibly usefull feature that lets you make changes to the raw image on the fly.  
# this wiill mount/umount fedora.raw to/from mnt_image/ 
# the chroot option will mount and arch-chroot you into mnt_image/
```
If the event that you make changes to the raw image in this manner   
run the following to generate a new `fedora.qcow2` image  
```qemu-img convert -f raw -O qcow2 mkosi.output/fedora.raw qemu/fedora.qcow2```

## To test out the fedora.qcow2 image  
```cd qemu```  
```./script-qemu.sh```  
\# the `script-qemu-sh` script can run on both `Linux` and `macos` systems  
\# once the image if confirmed as working  
\# you can literally transfer the entire `qemu/` directory to a `macos` system ane run `script-qemu-sh` on `macos` to boot the image  

## To build the image via `iso`
Simply run the following on either a `Linux` or `macos` system
```
git clone https://github.com/leifliddy/fedora-macos-asahi-qemu.git  
cd qemu/    
./script-qemu.sh --cdrom  
This will automatically download and boot from the latest `Fedora-Everything-netinst-aarch64` iso
To perform a graphical install, choose the 1) Start VNC option and connect a vnc client to port :5901
```

## /local_mnt
```/local_mnt``` is a directory with the VM that's shared with the host system.  
You can use it to transfer files to/from the VM  

## Rescuing a Fedora Asahi install  
You obvioulsy need to run this qemu VM in macos on an Apple Silicon mac that has Fedora Asahi Remix installed on it  
Two helper scripts have been added to the qemu image  
Which can help you rescue a Fedora Asahi Remix install:  
```
/usr/local/sbin/chroot.asahi
/usr/local/sbin/umount.asahi
```
1. `chroot.asahi` will mount the internal (Fedora) partitions under `/mnt` and will `arch-chroot` into it.  
To exit from the `chroot` environment, simply type `ctrl+d` or `exit`

2. `umount.asahi` will unmount the internal partitions from `/mnt`
<br/>

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/40d2268b-ef69-4045-8a66-ea47e11507bb" width=65%>
