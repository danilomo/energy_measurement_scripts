#!/bin/bash

read -d '' awk_script << 'EOF'
/PID/ {
     if(flag){
         next_ = NR;
     }else{
         flag = 1;
     }
 }

flag && NR == next_ + 1 && NR != 1 {
     print 0, 0, 0, $9, 0;
}
EOF

function sleep_until {
	t1=$(date -d "$*" +%s.%N)
	t2=$(date +%s.%N)

	seconds=$(echo "$t2 $t1" | awk '{x = $2 - $1; printf "%.4f\n", x;}')

	sleep $seconds
}

enddate=$(date -d "$dt +$2 seconds" +%s)
dtinseconds="0"

dt=$(date -d "$1")
pid=$5

logFile=$6
measuringInterval=$4

sleep_until $dt

while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
		
	#stats=$(pidstat -p $pid $measuringInterval 1 | awk 'NR == 4 { print $5, $6, $7, $8, $9}')
        stats=$(top -b -d $measuringInterval -n 2 -p $pid | awk "$awk_script")
	
	echo $timestamp $stats >> "./logFiles/log2_cpu_$logFile.txt"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
