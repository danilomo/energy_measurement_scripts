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

sleep_until $dt

while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
		
	stats=$(free | awk '/Mem/ {print $2, $3, $4, $5, $6, $7}')
	
	echo $timestamp $stats >> "./logFiles/log_memory.txt"
	
	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
