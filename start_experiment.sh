#!/bin/bash

# Get the PID of the qemu process by domain name
function getVMPid {
    ps aux | grep $1 | awk '/qemu/ { print $2 }'
}

# Sleep until a given date
function sleep_until {
	t1=$(date -d "$*" +%s.%N)
	t2=$(date +%s.%N)

	seconds=$(echo "$t2 $t1" | awk '{x = $2 - $1; printf "%.4f\n", x;}')

	sleep $seconds
}

netinterface=eno1

# Remove log files
./clean.sh 2&> /dev/null


# Start VMs and ensure they have SSH access
echo "Preparing VMs..."
python ./pythonScripts/prepare_vms.py "./configFiles/provider_config.json" "./configFiles/config.json"

baseTime=$(jq '.baseTime' experiment_config.json | sed -e 's/^"//' -e 's/"$//' )
experimentDuration=$(jq '.experimentDuration' experiment_config.json)
samplingInterval=$(jq '.samplingInterval' experiment_config.json)
provider=$(jq '.provider' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//')

# Start monitor processes for CPU, network, and IO of VMs
echo "Starting VM monitors..."
while read p; do
	pid=$(getVMPid $p)
	int=$(python ./pythonScripts/find_interface_name.py "./configFiles/provider_config.json" $provider $p)
	./monitorScripts/monitor_cpu_process.sh "$baseTime" $experimentDuration $samplingInterval $pid $p &
	./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $int &
	./monitorScripts/monitor_io_vm.sh "$baseTime" $experimentDuration $samplingInterval $p &		
done < instances.txt

# Start monitor process for power, CPU, network and IO of host
echo "Starting host monitors..."
./monitorScripts/monitor_energy.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_cpu.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_io.sh "$baseTime" $experimentDuration $samplingInterval &
./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netinterface &

p=$!

# Start benchmarks on VMs
echo "Starting benchmarks..."
python ./pythonScripts/start_experiment.py "./configFiles/provider_config.json" "./configFiles/config.json"


# Blocks until experiment ends
wait $p

echo "Experiment finished!"

# Cleaning up files
rm instances.txt
rm experiment_config.json
