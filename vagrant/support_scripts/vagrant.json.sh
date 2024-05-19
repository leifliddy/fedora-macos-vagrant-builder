#!/bin/bash

set -e

echo -e "\n############# running $(basename "$0") #############"
cur_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

## url examples
# url='fedora_40.box' (default -- will be derived from --name if not specified)
# url='https://leifliddy.com/vagrant/fedora_40.box'

usage=$(echo -e "Usage $(basename "$0") --name [IMAGE)\n
  -n, --name        name of the vagrant box
  -u, --url         can be the box name or a url path (it's the box name by default)
      --help        display this help and exit\n
")


while [[ $# -gt 0 ]];
do
    case $1 in
        --help) echo "$usage"; exit;;
        -n|--name) shift; vbox_image_name=$1;;
        -u|--url)  shift; url=$1;;
    esac
    shift
done


[[ -z $vbox_image_name ]] && echo "$usage" && exit
[[ $(echo $vbox_image_name | grep -E '\.box$') ]] && vbox_name=$vbox_image_name || vbox_name="${vbox_image_name}.box"
json_name="${vbox_image_name}.json"
date=$(date '+%Y%m%d')
vagrant_box_path="$(dirname $cur_dir)/$vbox_name"

[[ ! -f $vagrant_box_path ]] && echo "$vagrant_box_path doesn't exist" && exit
checksum_sha256=$(sha256sum $vagrant_box_path | awk '{print $1}')
[[ -z $url ]] && url=$vbox_name
echo "vbox_image_name: $vbox_image_name"
echo "url:  $url"

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

echo -e "json: $json_name"
