#!/bin/bash

read -d '' awk_script << 'EOF'
/Swap/{
    flag = 1;
}

/\%Cpu/ {
    if(flag){    
        sub(":", "", $0);
    
        core_num = substr( $1, 5 );
        filename = "log2_cpu_" core_num ".txt";
    
        print timestamp, $2, $6, $4, $10, $12, $14, $16, "0", "0", $8 >> "./logFiles/" filename;       
    }
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
measuringInterval=$4

dt=$(date -d "$1")

sleep_until $dt

while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
		
	#mpstat -P ALL $measuringInterval 1 | awk -v filename="./logFiles/log_cpu" -v time=$timestamp -f ./monitorScripts/process_cpu_log.awk

        top -b -d $measuringInterval -n 2 -p "0" | awk -v timestamp=$timestamp "$awk_script"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
