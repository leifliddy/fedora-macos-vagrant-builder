#!/bin/bash

# -w will point the url to https://leifliddy.com/vagrant/fedora_39.box vs fedora_39.box
image_name='fedora.qcow2'
#url=vbox_image_name='fedora_39'
vbox_image_name='fedora_39'
box_name="${vbox_image_name}.box"
web_url_box="https://leifliddy.com/vagrant/$box_name"
url=''
#json_name="${vbox_image_name}.json"


cur_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
fedora_hdd="$(dirname $cur_dir)/qemu/$image_name"

[[ -f $box_name ]] && rm -f $box_name
[[ ! -f $fedora_hdd ]] && echo "$fedora_hdd doesn't exist" && exit


while [ $# -gt 0 ]
do
    case $1 in
    --help) echo "$usage"; exit;;
    -u|--url) web_url=true;;
    (*) break;;
    esac
    shift
done

[[ $web_url = true ]] && url="--url $web_url_box"

# a reminder as I keep forgetting to set the web_url
[[ $web_url = true ]] && echo "url is set to $web_url" || echo $url is $box_name

# create vagrant box
$cur_dir/support_scripts/create_box.sh $fedora_hdd $box_name

# create json file
