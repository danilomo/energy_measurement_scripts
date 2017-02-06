#!/bin/bash
date +"%T.%N"
sshpass -p '12345' ssh teste@192.168.122.61 "date +\"%T.%N\""
sshpass -p '12345' ssh teste@192.168.122.34 "date +\"%T.%N\""
