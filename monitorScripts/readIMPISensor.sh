#!/bin/bash

t0=$(date +%s%3N)
total=$1
samples=$2
tf=$[$t0 + $total * 1000]
interval=$(echo "scale=5; $total / $samples - 0.027" | bc)

for i in `seq 1 $samples`; do
	val=$(sudo ipmi-sensors -r 3232 | awk 'NR == 2 { print $11 }')
	printf "$val "

	sleep $interval
done

echo
