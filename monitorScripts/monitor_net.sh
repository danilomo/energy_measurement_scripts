#!/bin/bash



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
netinterface=$4

sleep_until $dt



while [ $dtinseconds -le $enddate ]
do
	timestamp=$(date +%s%3N)
		
   eth01=`cat /proc/net/dev | grep $netinterface`
   sleep 1
   eth02=`cat /proc/net/dev | grep $netinterface`

   eth0download1=`echo $eth01 | awk '{print $2}'`
   eth0download2=`echo $eth02 | awk '{print $2}'`
   eth0download=`expr '(' $eth0download2 - $eth0download1 ')'`

   eth0upload1=`echo $eth01 | awk '{print $10}'`
   eth0upload2=`echo $eth02 | awk '{print $10}'`
   eth0upload=`expr '(' $eth0upload2 - $eth0upload1 ')'`

   eth0downpacket1=`echo $eth01 | awk '{print $3}'`
   eth0downpacket2=`echo $eth02 | awk '{print $3}'`
   eth0downpacket=`expr '(' $eth0downpacket2 - $eth0downpacket1 ')'`

   eth0uppacket1=`echo $eth01 | awk '{print $11}'`
   eth0uppacket2=`echo $eth02 | awk '{print $11}'`
   eth0uppacket=`expr '(' $eth0uppacket2 - $eth0uppacket1 ')'`
	
	echo $timestamp $eth0download $eth0upload $eth0downpacket $eth0uppacket >> "./logFiles/log_net_$netinterface.txt"

	dt=$(date -d "$dt +$3 seconds")

	sleep_until $dt

	dtinseconds=$(date +%s)
done
