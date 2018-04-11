#!/bin/bash

# Get the PID of the qemu process by domain name
function getVMPid {
    ps aux | grep $1 | awk '/qemu/ { print $2 }'
}

# Get the PID of the qemu process by domain name
function getVCPUID {
    sudo grep pid /var/run/libvirt/qemu/$1.xml | grep vcpu | grep -Eo "pid='[0-9]*'" | grep -Eo "[0-9]*"
}

pid=$(getVMPid $2)

sudo timeout $1 ./cpulimit -i -l $3 -p $pid >/dev/null 2>&1 &
