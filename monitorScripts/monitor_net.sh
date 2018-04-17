#!/bin/bash

read -d '' awkScript << 'EOF'
BEGIN{
    totalup = 0;
    totaldown = 0;
    total = 0;
    count = 0;
}

/total/ {
    totalup += $3;
    totaldown += $4;
    total += $5;
    count = count + 1;
}

END{
    avgup = totalup / count;
    avgdown = totaldown / count;
    avgtotal = total / count;
    printf("%.2f %.2f %.2f", avgup, avgdown, avgtotal);
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
netinterface=$4
measuringInterval=$5

sleep_until $dt



while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)

        samples=$(echo "2 * $measuringInterval" | bc | xargs printf "%.0f" )

        line=$(bwm-ng -c $samples -u bytes -o csv -I $netinterface -C " " | awk "$awkScript")

        echo $timestamp $line >> "./logFiles/log_net_$netinterface.txt"
        
	dt=$(date -d "$dt +$3 seconds")
	sleep_until $dt

	dtinseconds=$(date +%s)
done
