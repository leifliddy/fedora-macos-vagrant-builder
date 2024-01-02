#!/bin/bash

if (( $EUID != 0 )); then
    sudo='sudo'
fi

vagrant_box='fedora_39'
vagrant_name='fedora'

# this let's you console into a qemu Vagrantbox to troubleshoot errors occuring at boot time
# run 'vagrant up' and then immediately run ./serial-connect.sh in another window

# specify -d for debug output
while getopts :d arg
do
    case "${arg}" in
        d) debug=1;;
    esac
done

while [ $# -gt 0 ]
do
    case $1 in
    up) $sudo vagrant up;;
    halt) $sudo vagrant halt && exit;;
    reload) $sudo vagrant reload;;
    remove) $sudo vagrant box remove $vagrant_box && exit;;
    destroy) $sudo vagrant destroy $vagrant_box --force && exit;;
    --debug|debug) debug=1;;    
    -k|--kill|kill) $sudo ps -ef | grep .vagrant/machines/$vagrant_name/qemu | grep -v grep | awk '{print $2}' | xargs $sudo kill -9 && exit ;;
    --ssh|ssh) $sudo vagrant ssh $vagrant_name && exit;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*) break;;
    esac
    shift
done


shift $((OPTIND-1))

[[ -n $1 ]] && vm_name="$1" || vm_name=$vagrant_name

id_file=".vagrant/machines/$vm_name/qemu/id"

[[ $debug ]] && echo "checking .vagrant/machines/$vm_name/qemu/id"

[[ ! -f $id_file ]] && echo "$vm_name does not exist" && exit

vm_id=$(cat $id_file)
[[ -z $vm_id ]] && echo "$id_file is blank" && exit

socket="$HOME/.vagrant.d/tmp/vagrant-qemu/$vm_id/qemu_socket_serial"
[[ $debug ]] && echo /opt/homebrew/Cellar/qemu/8.2.0/share/qemu/edk2-aarch64-code.fd "checking $HOME/.vagrant.d/tmp/vagrant-qemu/$vm_id/qemu_socket_serial"

def upgrade_820_firmware() {
    # qemu 820 uses an outdated edk2 firmware version -- the new firmware version will be released with qemu version 8.2.1
    # after that time -- this logic can be deleted
    qemu_820_dir='/opt/homebrew/Cellar/qemu/8.2.0/share/qemu'
    md5_820='5f0854313a5795a2628f962b0a5a19b'
    current_md5_edk2=$(md5 -q $qemu_820_dir/edk2-aarch64-code.fd)
    echo $md5_820
    echo $current_md5_edk2

    if [ -f $qemu_820_dir/edk2-aarch64-code.fd ]; then
        if [ $current_md5_edk2 == $md5_820 ]; then
            cp $qemu_820_dir/edk2-aarch64-code.fd $qemu_820_dir/edk2-aarch64-code.fd.orig
            curl https://leifliddy.com/vagrant/edk2-aarch64-code.fd -O --output-dir $qemu_820_dir
            local_copy=$(find .vagrant/machines/$vagrant_name/qemu/ | grep edk2-aarch64-code.fd)
            if [ -f $local_copy ]; then
                $sudo cp $qemu_820_dir/edk2-aarch64-code.fd $local_copy
            fi
        fi   
    fi
}

[[ ! -S $socket ]] && echo "$vm_name is not currently running" && exit

[[ $debug ]] && echo -e "running:\nstty -icanon -echo && $sudo nc -U $socket"
stty -icanon -echo && $sudo nc -U $socket

# return the stty values back to their original state
stty sane
