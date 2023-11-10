#!/bin/bash

set -e

vbox_image_name='fedora_39'
box_name="${vbox_image_name}.box"
json_name="${vbox_image_name}.json"
date=$(date '+%Y%m%d')
cur_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
vagrant_box="$(dirname $cur_dir)/$box_name"

# used with the -w argument
web_url='https://leifliddy.com/vagrant/fedora_39.box'

[[ ! -f $vagrant_box ]] && echo "$vagrant_box doesn't exist" && exit
checksum_sha256=$(sha256sum $vagrant_box | awk '{print $1}')

while getopts :w arg
do
    case "${arg}" in
        w) is_url=true;;
    esac
done

[[ $is_url = true ]] && url=$web_url || url=$box_name

cat <<EOF > $json_name
{
    "name": "$vbox_image_name",
    "versions": [
        {
            "version": "$date",
            "providers": [
                {
                    "name": "libvirt",
                    "url": "$url",
                    "checksum_type": "sha256",
                    "checksum": "$checksum_sha256"
                }
            ]
        }
    ]
}
EOF

echo -e "\nwrote: $json_name\nwrote: $box_name"
