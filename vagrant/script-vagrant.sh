#!/bin/bash

# -w will point the url to https://leifliddy.com/vagrant/fedora_39.box vs fedora_39.box

while getopts :w arg
do
    case "${arg}" in
        w) web_url='-w';;
        *) web_url='';;
    esac
done

box_name='fedora_39.box'
cur_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

fedora_hdd="$(dirname $cur_dir)/qemu/fedora.qcow2"

[[ -f $box_name ]] && rm -f $box_name
[[ ! -f $fedora_hdd ]] && echo "$fedora_hdd doesn't exist" && exit

# create vagrant box
$cur_dir/support_scripts/create_box.sh $fedora_hdd $box_name

# create json file
$cur_dir/support_scripts/vagrant.json.sh $web_url
