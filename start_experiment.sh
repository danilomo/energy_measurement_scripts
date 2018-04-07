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

netinterface=eno1

# Create directory for log files, if it doesn't exist
mkdir -p ./logFiles


# Start VMs and ensure they have SSH access
echo "Preparing instances..."
python ./pythonScripts/prepare_instances.py "./configFiles/provider_config.json" "./configFiles/config.json"

baseTime=$(jq '.baseTime' experiment_config.json | sed -e 's/^"//' -e 's/"$//' )
experimentDuration=$(jq '.experimentDuration' experiment_config.json)
samplingInterval=$(jq '.samplingInterval' experiment_config.json)
provider=$(jq '.provider' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//')
limit=$(jq '.cpulimit' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//'	)
measuringInterval=$(jq '.measuringInterval // 1' ./configFiles/config.json)

# Start monitor processes for CPU, network, and IO of VMs
#echo "Starting VM monitors..."
#while read p; do
	#pid=$(getVMPid $p)
	#vcpupid=$(getVCPUID $p)

	#int=$(python ./pythonScripts/find_interface_name.py "./configFiles/provider_config.json" $provider $p)
	#./monitorScripts/monitor_cpu_process.sh "$baseTime" $experimentDuration $samplingInterval $vcpupid $p $measuringInterval &
	#./monitorScripts/monitor_memory_process.sh "$baseTime" $experimentDuration $samplingInterval $pid $p &
	#./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $int $measuringInterval &
	#./monitorScripts/monitor_io_vm.sh "$baseTime" $experimentDuration $samplingInterval $p $measuringInterval &
#done < instances.txt

# Start monitor process for power, CPU, network and IO of host
echo "Starting host monitors..."
./monitorScripts/monitor_energy_IPMI.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
#./monitorScripts/monitor_energy.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
./monitorScripts/monitor_cpu.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
./monitorScripts/monitor_memory.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_io.sh "$baseTime" $experimentDuration $samplingInterval $measuringInterval &
./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netinterface $measuringInterval &

p=$!

# Start benchmarks on VMs
echo "Starting benchmarks..."
python ./pythonScripts/start_experiment.py "./configFiles/provider_config.json" "./configFiles/config.json"
echo "Iniciou benchmarks."

wait $p

echo "Experiment finished!"

# Cleaning up files
rm -rf instances.txt
rm -rf experiment_config.json
