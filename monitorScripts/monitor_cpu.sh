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
		
	stats=$(mpstat -P ALL 1 1 | awk 'NR == 4 {all_usr = $4;all_nice = $5;all_sys = $6;}NR == 5 {c1_usr = $4;c1_nice = $5;c1_sys = $6;}NR == 6 {c2_usr = $4;c2_nice = $5;c2_sys = $6;}NR == 7 {c3_usr = $4;c3_nice = $5;c3_sys = $6;}NR == 8 {c4_usr = $4;c4_nice = $5;c4_sys = $6;}END {print all_usr, all_nice, all_sys, c1_usr, c1_nice, c1_sys,  c2_usr, c2_nice, c2_sys,  c3_usr, c3_nice, c3_sys,  c4_usr, c4_nice, c4_sys}')
	
	echo $timestamp $stats >> "./logFiles/log_cpu.txt"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
