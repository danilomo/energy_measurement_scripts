#!/bin/bash

# Get the PID of the qemu process by domain name
function getVMPid {
    ps aux | grep $1 | awk '/qemu/ { print $2 }'
}

function sleep_until {
	t1=$(date -d "$*" +%s.%N)
	t2=$(date +%s.%N)

	seconds=$(echo "$t2 $t1" | awk '{x = $2 - $1; printf "%.4f\n", x;}')

	#echo "Sleepou $seconds seconds."

	sleep $seconds
}

netinterface=eno1

./clean.sh 2&> /dev/null

python ./pythonScripts/prepare_vms.py "./configFiles/provider_config.json" "./configFiles/config.json"

baseTime=$(jq '.baseTime' experiment_config.json | sed -e 's/^"//' -e 's/"$//' )
experimentDuration=$(jq '.experimentDuration' experiment_config.json)
samplingInterval=$(jq '.samplingInterval' experiment_config.json)
provider=$(jq '.provider' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//')

while read p; do
	pid=$(getVMPid $p)
	int=$(python ./pythonScripts/find_interface_name.py "./configFiles/provider_config.json" $provider $p)
#	./monitorScripts/monitor_cpu_process.sh "$baseTime" $experimentDuration $samplingInterval $pid $p &
#	./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $int &
#	./monitorScripts/monitor_io_vm.sh "$baseTime" $experimentDuration $samplingInterval $p &		
done < instances.txt

#./monitorScripts/monitor_energy.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_cpu.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_io.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netinterface &

#sleep_until $baseTime
python ./pythonScripts/start_experiment.py "./configFiles/provider_config.json" "./configFiles/config.json"

p=$!
wait $p


#python ./pythonScripts/collect_files.py "./configFiles/provider_config.json" "./configFiles/config.json"

rm instances.txt
rm experiment_config.json
