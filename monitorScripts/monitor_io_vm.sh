#!/bin/bash

netinterface=eno1

function sleep_until {
	t1=$(date -d "$*" +%s.%N)
	t2=$(date +%s.%N)

	seconds=$(echo "$t2 $t1" | awk '{x = $2 - $1; printf "%.4f\n", x;}')

	sleep $seconds
}

enddate=$(date -d "$dt +$2 seconds" +%s)
dtinseconds="0"

dt=$(date -d "$1")
domainname=$4
measuringInterval=$5

sleep_until $dt

while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
	
	filter="/$domainname/"
	filter+=' { read = $4; write = $6; } BEGIN { read = 0.0; write = 0.0; } END { print read, write }'
	#echo "awk $filter"
	
	stats=$(sudo iotop -b -n 2 -k -o -d $measuringInterval | awk "$filter")
	
	echo $timestamp $stats >> "./logFiles/log_io_$domainname.txt"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
