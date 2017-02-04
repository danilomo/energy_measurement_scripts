#!/bin/bash

# Get the PID of the qemu process by domain name
function getVMPid {
    ps aux | grep $1 | awk '/qemu/ { print $2 }'
}

netinterface=eno1

python ./pythonScripts/master_script.py "./configFiles/provider_config.json" "./configFiles/config.json"

baseTime=$(jq '.baseTime' experiment_config.json | sed -e 's/^"//' -e 's/"$//' )
experimentDuration=$(jq '.experimentDuration' experiment_config.json)
samplingInterval=$(jq '.samplingInterval' experiment_config.json)
provider=$(jq '.provider' ./configFiles/config.json | sed -e 's/^"//' -e 's/"$//')

echo $provider

while read p; do
	pid=$(getVMPid $p)
	#./monitorScripts/monitor_process.sh "$baseTime" $experimentDuration $samplingInterval $pid $p &
done < instances.txt

#./monitorScripts/monitor_energy.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_cpu.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_io.sh "$baseTime" $experimentDuration $samplingInterval &
#./monitorScripts/monitor_net.sh "$baseTime" $experimentDuration $samplingInterval $netinterface&

#p=$!

#wait $p


python ./pythonScripts/collect_files.py "./configFiles/provider_config.json" "./configFiles/config.json"

rm instances.txt
rm experiment_config.json
