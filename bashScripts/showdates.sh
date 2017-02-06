#!/bin/bash
dt=$(date)
sudo date -s "$dt"
sshpass -p '12345' ssh teste@192.168.122.61 "sudo date -s \"$dt\""
sshpass -p '12345' ssh teste@192.168.122.34 "sudo date -s \"$dt\""
