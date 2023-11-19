#!/bin/bash

# -w will point the url to https://leifliddy.com/vagrant/fedora_39.box vs fedora_39.box
image_name='fedora.qcow2'
vbox_image_name='fedora_39'
box_name="${vbox_image_name}.box"
web_url_box="https://leifliddy.com/vagrant/$box_name"
kill='kill'
vagrant='vagrant'
url=''

cur_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
fedora_hdd="$(dirname $cur_dir)/qemu/$image_name"

[[ $(uname -a | grep -i darwin) ]] && macos=true
[[ $(uname -a | grep -i linux) ]] && linux=true

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
        $kill -9 $qemu_pid
    done
}

if [[ $macos == true ]] && [[ $EUID -ne 0 ]]; then
    echo "You need to run this script as root or sudo when running from macos"
    vagrant='sudo vagrant'
    kill='sudo kill'
    exit 1
fi

while [ $# -gt 0 ]
do
    case $1 in
    --help) echo "$usage"; exit;;
    -w|--url) web_url=true;;
    -k|--kill) kill_vagrant_fedora; exit;;
    -d|--destroy) $vagrant halt; $vagrant destroy -f; exit;;
    -h|--halt) $vagrant halt; exit;;
    -l|--list) vagrant box list; exit;;
    -r|--reload) $vagrant reload; exit;;
    -u|--up) $vagrant up; exit;;
    (*) break;;
    esac
    shift
done

[[ $web_url = true ]] && url="--url $web_url_box"

# create vagrant box]
#echo "fedora_hdd is $fedora_hdd"
#echo "box_name is $box_name"
#echo "$cur_dir/support_scripts/create_box.sh $fedora_hdd $box_name"
$cur_dir/support_scripts/create_box.sh $fedora_hdd $box_name

# create json file
$cur_dir/support_scripts/vagrant.json.sh --name $vbox_image_name $url

# these files names are hard-coded -- need to submit a PR for that
# https://github.com/ppggff/vagrant-qemu/blob/4d85f60032bf0a4ef3f7d26f4a102fce1f3213f2/lib/vagrant-qemu/driver.rb#L158C7-L158C7

if [[ $linux = true ]]; then
    [[ ! -f 'support_scripts/edk2-aarch64-code.fd' ]] && cp /usr/share/edk2/aarch64/QEMU_EFI-silent-pflash.raw support_scripts/edk2-aarch64-code.fd
    [[ ! -f 'support_scripts/edk2-arm-vars.fd' ]] && cp /usr/share/edk2/aarch64/vars-template-pflash.raw support_scripts/edk2-arm-vars.fd

    is_active=$(systemctl is-active libvirtd)
    [[ $is_active != 'active' ]] && systemctl restart libvirtd
fi

echo -e "\n#################### summary ######################"
vbox_exists=$(vagrant box list | grep "^${vbox_image_name} ")
if [[ -n $vbox_exists ]]; then
    echo -e "\nnote: the vagrant box $vbox_image_name is already installed\n$vbox_exists"
else
    echo -e "\nyou can install the $vbox_image_name box with either"
    echo "vagrant box add ${vbox_image_name}.json\nor vagrant box add ${vbox_image_name}.box"
fi

