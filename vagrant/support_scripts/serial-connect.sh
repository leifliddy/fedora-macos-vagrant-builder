#!/bin/bash


# this let's you console into a qemu Vagrantbox to troubleshoot errors occuring at boot time
# run 'vagrant up' and then immediately run ./serial-connect.sh in another window

# specify -d for debug output
while getopts :d arg
do
    case "${arg}" in
        d) debug=1;;
    esac
done

shift $((OPTIND-1))

#[[ -z $1 ]] && echo 'usage is serial-connect.sh [VM NAME]' && exit
[[ -n $1 ]] && vm_name="$1" || vm_name='fedora'

id_file=".vagrant/machines/$vm_name/qemu/id"

[[ $debug ]] && echo "checking .vagrant/machines/$vm_name/qemu/id"

[[ ! -f $id_file ]] && echo "$vm_name does not exist" && exit

vm_id=$(cat $id_file)
[[ -z $vm_id ]] && echo "$id_file is blank" && exit

socket="$HOME/.vagrant.d/tmp/vagrant-qemu/$vm_id/qemu_socket_serial"
[[ $debug ]] && echo "checking $HOME/.vagrant.d/tmp/vagrant-qemu/$vm_id/qemu_socket_serial"

[[ ! -S $socket ]] && echo "$vm_name is not currently running" && exit


#[[ $debug ]] && echo -e "running:\nstty raw && nc -U $socket"
#stty raw && nc -U $socket

[[ $debug ]] && echo -e "running:\nstty -icanon -echo && nc -U $socket"
stty -icanon -echo && nc -U $socket

# hit ctrl-c to exit from the console
# once you're back to the macos terminal type:
# stty sane
# to return the tty setting back to their original state

