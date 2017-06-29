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

dt=$(date -d "$1")
pid=$4

if [ -z "$6" ];
then
	logFile=$pid
	measuringInterval=$5
else
	logFile=$5
	measuringInterval=$6	
fi

sleep_until $dt

while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
		
	stats=$(pidstat -p $pid $measuringInterval 1 | awk 'NR == 4 { print $5, $6, $7, $8, $9}')
	
	echo $timestamp $stats >> "./logFiles/log_cpu_$logFile.txt"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
