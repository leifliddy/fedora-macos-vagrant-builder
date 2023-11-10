# Fedora qemu Asahi image
Builds and runs minimal Fedora `qemu` image that can be converted into a `vagrant` box  
**Note:** Currently this image must be built on a `Fedora 39` system with `mkosi` installed from main  

Can be used to rescue a Fedora Asahi Linux system  

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/293087dd-384b-4566-a4c2-6431596f7c31" width=65%>
<br/>
<br/>

## Deploying a pre-buit Vagrant Box to rescue a Fedora Asahi Remix installation
**Note:** This is an experimental/new feature. The scripts will become better developed over the next week or so....    

Ensure this packages/plugins are installed on macos:
```
brew reinstall qemu vagrant
vagrant plugin install vagrant-qemu
```
Then just run the following to download and start a Fedora 39 vagrant box:
```
# A Vagrantfile should go in its own directory
mkdir vagrant-fedora
cd vagrant-fedora
curl https://leifliddy.com/vagrant.sh | sh
```
**Note:** if you ever decide to remove this Vagrantbox in the future   
Ensure you remove this subdirectory   

```
[leif.liddy@m1 vagrant-fedora]$ rm -rf .vagrant/
```

You should now see the `fedora_39` Vagrantbox installed
```
[leif.liddy@m1 ~]$ vagrant box list
fedora_39      (libvirt, 20231109)
```
Use any of these methods to ssh in the `fedora` Vagrantbox   
```
vagrant ssh 
vagrant ssh fedora 
ssh -l root -i $(vagrant ssh-config | grep IdentityFile | awk '{print $2}') -p 3333 localhost
```

Once you've verifed it boots and you can ssh into it, then run:   
```vagrant halt```   
**Note:** I've encountered a few instances where `vagrant halt` didn't kill the VagrantBox -- just something to be aware of  

Now uncomment this line in the Vagrantfile -- this will allow vagrant to gain access to the internal linux partitions   
`linux_partitions = '-drive if=virtio,format=raw,file=/dev/disk0s4 -drive if=virtio,format=raw,file=/dev/disk0s5 -drive if=virtio,format=raw,file=/dev/disk0s6'`

**Note:** `sudo` is needed to mount the linux partitions -- but it also jacks with the vagrant permissions   
which meants after running `sudo vagrant ...` the first time -- every subsequent vagrant command needs to be run with `sudo vagrant`    

So to `chroot` into your Fedora Asahi Remix installation:   
```
sudo vagrant up
sudo vagrant ssh 
chroot.asahi
```
You should now be chroot'd into your Fedora Asahi Remix install  

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/acd2bded-8e38-4e0f-ab73-79209072a051" width=65%>

## Building the image   
The image can be built via `mkosi` or via booting and installing via an `iso` image

## Fedora Packages needed to build and run the image  
```dnf install arch-install-scripts bubblewrap mtools qemu-img qemu-system-aarch64```

## macos Packages needed to run the image      
```brew install qemu```

### Notes
- The root password is **fedora**
- Once the VM is running you can connect to it via ssh port 2222 ie ```ssh -l root -p 2222 m1```  
- ```qemu-user-static``` is needed if building the image on a ```non-aarch64``` system  
- Building the image on a **Fedora 39** system currently requires that you install `mkosi` from main:  
  `python3 -m pip install --user git+https://github.com/systemd/mkosi.git`

## To build the image via `mkosi`
```# sudo is needed to mount the linux partitions -- but it also jacks with the vagrant permissions # which meants after running vagrant with sudo -- every subsequent vagrant command needs to run with sudo  # so now run 
# This needs to be built on a Fedora 39 system
./build.sh
# this will create the following images:
1. mkosi.output/fedora.raw
2. qemu/fedora.qcow2 (this is simply a compressed version of fedora.raw that's used with qemu)
```

## To mount/umount/ the fedora.raw image  
```
./build {mount, umount, chroot}
This is in incredibly useful feature that lets you make changes to the raw image on the fly  
# this will mount/umount fedora.raw to/from mnt_image/ 
# the chroot option will mount and arch-chroot you into mnt_image/
```
If the event that you make changes to the raw image in this manner   
run the following to generate a new `fedora.qcow2` image  
```qemu-img convert -f raw -O qcow2 mkosi.output/fedora.raw qemu/fedora.qcow2```

## To test out the fedora.qcow2 image  
```cd qemu```  
```./script-qemu.sh```  
\# the `script-qemu-sh` script can run on either a `linux` or `macos` system  
\# once the image if confirmed as working on `linux`  
\# you can literally transfer the entire `qemu/` directory to a `macos` system ane run `script-qemu-sh` on `macos` to boot the image  

## To build the image via `iso`
Simply run the following on either a `linux` or `macos` system
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
You obvioulsy need to run this qemu VM on an Apple Silicon mac that has Fedora Asahi Remix installed on it  
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
