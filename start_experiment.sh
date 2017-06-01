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
echo "Preparing VMs..."
python ./pythonScripts/prepare_vms.py "./configFiles/provider_config.json" "./configFiles/config.json"

baseTime=$(jq '.baseTime' experiment_config.json | sed -e 's/^"//' -e 's/"$//' )
experimentDuration=$(jq '.experimentDuration' experiment_config.json)
samplingInterval=$(jq '.samplingInterval' experiment_config.json)
provider=$(jq '.provider' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//')
limit=$(jq '.cpulimit' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//'	)


# Start monitor processes for CPU, network, and IO of VMs
echo "Starting VM monitors..."
while read p; do
	pid=$(getVMPid $p)
	vcpupid=$(getVCPUID $p)
	
	int=$(python ./pythonScripts/find_interface_name.py "./configFiles/provider_config.json" $provider $p)
	./monitorScripts/monitor_cpu_process.sh "$baseTime" $experimentDuration $samplingInterval $vcpupid $p &
	./monitorScripts/monitor_memory_process.sh "$baseTime" $experimentDuration $samplingInterval $pid $p &	
	./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $int &
	./monitorScripts/monitor_io_vm.sh "$baseTime" $experimentDuration $samplingInterval $p &		
done < instances.txt

# Start monitor process for power, CPU, network and IO of host
echo "Starting host monitors..."
./monitorScripts/monitor_energy_IPMI.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_energy.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_cpu.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_memory.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_io.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netinterface &

p=$!

# Start benchmarks on VMs
echo "Starting benchmarks..."
python ./pythonScripts/start_experiment.py "./configFiles/provider_config.json" "./configFiles/config.json"


# put limit on VM process, if field set on the JSON file
if [ "$limit" != "null" ]; then
	while read p; do
		pid=$(getVMPid $p)
		sudo timeout $experimentDuration cpulimit -p $pid -l $limit &			
	done < instances.txt
fi

wait $p

echo "Experiment finished!"

# Cleaning up files
rm instances.txt
rm experiment_config.json
