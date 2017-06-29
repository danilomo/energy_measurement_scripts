#!/bin/bash

netinterface=eno1

function sleep_until {
	t1=$(date -d "$*" +%s.%N)
	t2=$(date +%s.%N)

	seconds=$(echo "$t2 $t1" | awk '{x = $2 - $1; printf "%.4f\n", x;}')

	#echo "Sleepou $seconds seconds."

	sleep $seconds
}

enddate=$(date -d "$dt +$2 seconds" +%s)
dtinseconds="0"
measuringInterval=$4

dt=$(date -d "$1")

sleep_until $dt

while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
		
	stats=$(sudo iotop -b -n 2 -k -o -d $measuringInterval | awk '/Total/ { read = $5; write = $12; } END { print read, write }')
	
	echo $timestamp $stats >> "./logFiles/log_io.txt"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
