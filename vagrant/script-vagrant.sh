#!/bin/bash

#set -x

# -w will point the url to https://leifliddy.com/vagrant/fedora_40.box vs fedora_40.box
image_name='fedora.qcow2'
vbox_image_name='fedora_40'
box_name="${vbox_image_name}.box"
web_url_box="https://leifliddy.com/vagrant/$box_name"
kill='kill'
vagrant='vagrant'
url=''

cur_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
fedora_hdd="$(dirname $cur_dir)/qemu/$image_name"


qemu_plugin_installed=$(vagrant plugin list | grep vagrant-qemu)
if [[ -z $qemu_plugin_installed ]]; then
    echo -e 'the vagrant-qemu plugin is not installed\ninstall it with:\nvagrant plugin install vagrant-qemu'
    exit
fi

[[ -f $box_name ]] && rm -f $box_name
[[ ! -f $fedora_hdd ]] && echo "$fedora_hdd doesn't exist" && exit

kill_vagrant_fedora() {
    qemu_pid=$(pgrep -f 'vagrant/machines/fedora/qemu' || true)
    for pid in $qemu_pid
    do
        kill -9 $qemu_pid
    done
}

usage() {
cat << EOF
Usage: ./script-vagrant.sh [OPTION]

  -R, --recursive            list subdirectories recursively
  -w, --url                  modify the url in $vbox_image_name.json with $web_url_box
  -k, --kill                 kill every instance of this box that\'s running
  -d, --destroy              stops and deletes all traces of the vagrant machine
  -h, --halt                 stops the vagrant machinestops the vagrant machinev
  -l, --list                 list all available vagrant boxes
      --remove               remove the vagrant box $vbox_image_name (if it exists)
  -r, --reload               restarts vagrant machine, loads new Vagrantfile configuration
  -u, --up                   starts and provisions the vagrant environment

      --help        display this help and exit
EOF
}

while [ $# -gt 0 ]
do
    case $1 in
    --help) usage; exit;;
    -w|--url) web_url=true;;
    -k|--kill) kill_vagrant_fedora; exit;;
    -d|--destroy) vagrant halt; vagrant destroy -f; exit;;
    -h|--halt) vagrant halt; exit;;
    -l|--list) vagrant box list; exit;;
    -r|--reload) vagrant reload; exit;;
    --remove) vagrant box remove $vbox_image_name; exit;;
    -u|--up) vagrant up; exit;;
    (*) break;;
    esac
    shift
done

[[ $web_url = true ]] && url="--url $web_url_box"

# create vagrant box
$cur_dir/support_scripts/create_box.sh $fedora_hdd $box_name

# create json file
$cur_dir/support_scripts/vagrant.json.sh --name $vbox_image_name $url

# these files names are hard-coded -- need to submit a PR for that
# https://github.com/ppggff/vagrant-qemu/blob/master/lib/vagrant-qemu/driver.rb


[[ ! -f 'support_scripts/edk2-aarch64-code.fd' ]] && cp /usr/share/edk2/aarch64/QEMU_EFI-silent-pflash.raw support_scripts/edk2-aarch64-code.fd
[[ ! -f 'support_scripts/edk2-arm-vars.fd' ]] && cp /usr/share/edk2/aarch64/vars-template-pflash.raw support_scripts/edk2-arm-vars.fd

libvirtd_exists=$(systemctl list-unit-files | grep libvirtd.service)
is_active=$(systemctl is-active libvirtd)
[[ -n $libvirtd_exists ]] && [[ $is_active != 'active' ]] && systemctl restart libvirtd


echo -e "\n#################### summary ######################"
vbox_exists=$(vagrant box list | grep "^${vbox_image_name} ")
if [[ -n $vbox_exists ]]; then
    echo -e "\nnote: the vagrant box $vbox_image_name is already installed\n$vbox_exists"
else
    echo -e "\nyou can install $box_name with either:\n"
    echo -e "vagrant box add ${vbox_image_name}.json\nor\nvagrant box add $box_name"
    echo -e "\n\n**please note that when installing via the json file, the url in ${vbox_image_name}.json\nwill be used as the location to download the image from"

fi
