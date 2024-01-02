#!/bin/bash

if (( $EUID != 0 )); then
    sudo='sudo'
fi

vagrant_box='fedora_39'
vagrant_name='fedora'

# update qemu 820 firmware to 821 firmware
upgrade_qemu_firmware() {
    # qemu 820 uses an outdated edk2 firmware version -- the new firmware version will be released with qemu version 8.2.1
    # after that time -- this entire next block can be deleted
    qemu_dir='/opt/homebrew/Cellar/qemu/8.2.0/share/qemu'
    md5_sum_edk_file_correct='95f0854313a5795a2628f962b0a5a19b'
    md5_sum_edk_file_actual=$(md5 -q $qemu_dir/edk2-aarch64-code.fd)

    if [ -f $qemu_dir/edk2-aarch64-code.fd ]; then
        if [ $md5_sum_edk_file_correct != $md5_sum_edk_file_actual ]; then
            curl https://leifliddy.com/vagrant/edk2-aarch64-code.fd -O --output-dir $qemu_dir/
            echo "find .vagrant/machines/$vagrant_name/qemu/ | grep edk2-aarch64-code.fd"
            local_copy=$(find .vagrant/machines/$vagrant_name/qemu/ | grep edk2-aarch64-code.fd)
            if [ -f $local_copy ]; then
                echo "$sudo cp $qemu_dir/edk2-aarch64-code.fd $local_copy"
                $sudo cp $qemu_dir/edk2-aarch64-code.fd $local_copy
            fi
        fi
    fi
}

console() {
    echo ".vagrant/machines/$vagrant_name/qemu/id"
    id_file=".vagrant/machines/$vagrant_name/qemu/id"

    [[ $debug ]] && echo "checking .vagrant/machines/$vm_name/qemu/id"

    [[ ! -f $id_file ]] && echo "$vm_name does not exist" && exit

    vm_id=$(cat $id_file)
    [[ -z $vm_id ]] && echo "$id_file is blank" && exit

    socket="$HOME/.vagrant.d/tmp/vagrant-qemu/$vm_id/qemu_socket_serial"

    [[ ! -S $socket ]] && echo "$vm_name is not currently running" && exit

    [[ $debug ]] && echo -e "$sudo nc -U $socket"
    stty -icanon -echo && $sudo nc -U $socket

    stty sane
}

while [ $# -gt 0 ]
do
    case $1 in
    up) upgrade_qemu_firmware && $sudo vagrant up;;
    halt) $sudo vagrant halt && exit;;
    reload) $sudo vagrant reload;;
    remove) $sudo vagrant box remove $vagrant_box && exit;;
    destroy) $sudo vagrant destroy $vagrant_name --force && exit;;

    -d|--debug|debug) debug=1;;
    -k|--kill|kill) $sudo ps -ef | grep .vagrant/machines/$vagrant_name/qemu | grep -v grep | awk '{print $2}' | xargs $sudo kill -9 && exit ;;
    --ssh|ssh) $sudo vagrant ssh $vagrant_name && exit;;
    -console|console) console $vagrant_name && exit;;
    (*) break;;
    esac
    shift
done

shift $((OPTIND-1))
