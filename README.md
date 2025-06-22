# Fedora qemu Asahi image
Builds a minimal Fedora `qemu` image that can be converted into a `vagrant` box  
**Note:** Currently this image must be built on a `Fedora 42` system

This can be used to rescue a Fedora Asahi Linux system from within macos  

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/9b93c15c-11eb-44fd-a602-2c8efc26024b" width=65%>
<br/>
<br/>

## Deploying a pre-built Vagrant Box to rescue a Fedora Asahi Remix installation
**Note:** Although this image can be run on both **macos** and **Fedora** systems -- the main use-case is **macos**  

Ensure these packages/plugins are installed on `macos`:
```
brew install qemu vagrant
vagrant plugin install vagrant-qemu
```
If running on `Fedora`, ensure these package are installed on `Fedora`:   
```
dnf install qemu-img qemu-system-aarch64 vagrant
vagrant plugin install vagrant-qemu
```
Then just run the following to download and start a Fedora 42 vagrant box:
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

You should now see the `fedora_42` Vagrantbox installed
```
[leif.liddy@m1 ~]$ vagrant box list
fedora_42      (libvirt, 20250622)
```
So to `ssh` and `chroot` into your Fedora Asahi Remix installation (when running on `macos`)   
```
./vagrant ssh
chroot.asahi
```

**Note:** I've encountered a few instances where `vagrant halt` didn't kill the VagrantBox -- in that case run `./vagrant kill`

**Note:** `sudo` is needed to mount the linux partitions on `macos` systems -- but it also messes with the vagrant permissions   
which means after running `sudo vagrant ...` the first time -- every subsequent `vagrant` command needs to be run with `sudo vagrant`    

The `Vagrantfile` config and `vagrant` scripts will run the sudo comands automatically (on **macos** systems  ) -- you'll just need to enter your sudo password  

**Note:** `sudo` is not needed if running on a Linux system  

You should now be chroot'd into your Fedora Asahi Remix install  

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/acd2bded-8e38-4e0f-ab73-79209072a051" width=65%>

## Building the image   
The image can be built via `mkosi` or via booting and installing via an `iso` image

## Fedora Packages needed to build and run the image  
```dnf install arch-install-scripts bubblewrap kpartx mkosi mtools qemu-img qemu-system-aarch64```

## macos Packages needed to run the image      
```brew install qemu```

### Notes
- The root password is **fedora**
- Once the VM is running you can connect to it via ssh port 2222 ie ```ssh -l root -p 2222 m1```  
- ```qemu-user-static``` is needed if building the image on a ```non-aarch64``` system  
- This project is based on `mkosi v24` which matches the current version of `mkosi` in the `F42` repo
  https://src.fedoraproject.org/rpms/mkosi/  
  However....`mkosi` is updated so quickly that it's difficult to keep up at times (I have several projects based on `mkosi`)  
  I'll strive to keep things updated to the latest version supported in Fedora  
  If needed, you can always install a specific version via pip  
  `python3 -m pip install --user git+https://github.com/systemd/mkosi.git@v24`

## To build the image via `mkosi`
```# sudo is needed to mount the linux partitions -- but it also jacks with the vagrant permissions # which meants after running vagrant with sudo -- every subsequent vagrant command needs to run with sudo  # so now run 
# This needs to be built on a Fedora 42 system
./build.sh
# this will create the following images:
1. mkosi.output/fedora.raw
2. qemu/fedora.qcow2 (this is simply a compressed version of fedora.raw that's used with qemu)
```

## To mount/umount/ the fedora.raw image  
```
./build mount
./build chroot
./build umount
```
This is in incredibly useful feature that lets you make changes to the raw image on the fly  
This will mount/chroot/umount fedora.raw to/from mnt_image/  

If the event that you make changes to the raw image in this manner   
run the following to generate a new `fedora.qcow2` image  
```qemu-img convert -f raw -O qcow2 mkosi.output/fedora.raw qemu/fedora.qcow2```

## Use qemu to run the fedora.qcow2 image  
```
cd qemu
./script-qemu.sh
```  
\# the `script-qemu-sh` script can run on either a `linux` or `macos` system  
\# once the image if confirmed as working on `linux`  
\# you can literally transfer the entire `qemu/` directory to a `macos` system ane run `script-qemu-sh` on `macos` to boot the image  

## Create a vagrant box
Creates a vagrant box from the `fedora.cow2` image produced in the previous steps  
```
cd vagrant
./script-vagrant.sh
```
This script is only supported on Linux at the moment  
The output will produce two files
```
fedora_42.box
fedora_42.json
```
Although you can add a vagrant box directly -- it's better add it via the json file  
To add a new vagrant box 
```
vagrant box add fedora_42.json
```

## To perform a Fedora installation via an `iso` image
Simply run the following on either a `linux` or `macos` system
```
git clone https://github.com/leifliddy/fedora-macos-asahi-qemu.git
cd qemu/
./script-qemu.sh --cdrom
This will automatically download and boot from the latest `Fedora-Everything-netinst-aarch64` iso
To perform a graphical install, choose the 1) Start VNC option and connect a vnc client to port :5901
```

## /local_mnt
```/local_mnt``` is a directory located within the VM that's shared with the host system.  
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

<img src="https://github.com/leifliddy/fedora-macos-asahi-qemu/assets/12903289/40d2268b-ef69-4045-8a66-ea47e11507bb" width=65%>

## Using vagrant.sh
`vagrant.sh` enforces `sudo`, so it's a bit more convenient then having to type 'sudo vagrant` for every command
```
./vagrant up       # brings up the vagrant box
./vagrant ssh      # ssh into the vagrant box
./vagrant halt     # stop the vagrant box
./vagrant reload   # restarts the vagrant box
./vagrant destroy  # destroys the vagrant box instance
./vagrant remove   # removes the vagrant box image
./vagrant kill     # kills any running instance of the vagrant box (only use if ./vagrant halt doens't work)
./vagrant console  # this let's you console into a qemu Vagrantbox to troubleshoot errors occuring at boot time
                   # run './vagrant up' and then immediately run ./vagrant console in another window
                   # to view the console
```
