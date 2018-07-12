#!/bin/bash

# Get the PID of the qemu process by domain name
function getVMPid {
    ps aux | grep $1 | awk '/qemu/ { print $2 }'
}

# Get the PID of the qemu process by domain name
function getVCPUID {
    sudo grep pid /var/run/libvirt/qemu/$1.xml | grep vcpu | grep -Eo "pid='[0-9]*'" | grep -Eo "[0-9]*"
}

# Sleep until a given date
function sleep_until {
    t1=$(date -d "$*" +%s.%N)
    t2=$(date +%s.%N)

    seconds=$(echo "$t2 $t1" | awk '{x = $2 - $1; printf "%.4f\n", x;}')

    sleep $seconds
}

netinterface=br0

# Create directory for log files, if it doesn't exist
mkdir -p ./logFiles


# Start VMs and ensure they have SSH access
echo "Preparing instances..."
python ./pythonScripts/prepare_instances.py "./configFiles/provider_config.json" "./configFiles/config.json"


baseTime=$(jq '.baseTime' experiment_config.json | sed -e 's/^"//' -e 's/"$//' )
experimentDuration=$(jq '.experimentDuration' experiment_config.json)
samplingInterval=$(jq '.samplingInterval' experiment_config.json)
provider=$(jq '.provider' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//')
limit=$(jq '.cpulimit' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//'  )
measuringInterval=$(jq '.measuringInterval // 1' ./configFiles/config.json)

# Start monitor processes for each VCPU
for i in $(./pythonScripts/libvirtutils.py instances)
do
	pid=$(getVMPid $i)	
    vcpupid=$(getVCPUID $i)
	netint=$(./pythonScripts/libvirtutils.py network_int $i)
    ./monitorScripts/monitor_cpu_process.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval $vcpupid $i &
	./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netint $measuringInterval &
	./monitorScripts/monitor_io_vm.sh "$baseTime" $experimentDuration $samplingInterval $i $measuringInterval $pid &
done


# Start monitor process for power, CPU, network and IO of host
echo "Starting host monitors..."
./monitorScripts/monitor_energy_IPMI.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
./monitorScripts/monitor_cpu.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
./monitorScripts/monitor_memory.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_io.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netinterface $measuringInterval &


p=$!

# Start benchmarks on VMs
echo "Starting benchmarks..."

python ./pythonScripts/start_experiment.py "./configFiles/provider_config.json" "./configFiles/config.json" &

echo "Benchmarks started."

wait $p

echo "Experiment finished!"

# Cleaning up files
rm -rf instances.txt
rm -rf experiment_config.json
