#!/bin/bash

str=$(docker ps -f name=ubuntu01 -q)
while [ -z "$str" ]; do
    sleep 0.1;
    str=$(docker ps -f name=ubuntu01 -q)
done;

contName=$1
contPid=$(docker ps -q | xargs docker inspect --format '{{.State.Pid}}, {{.Name}}' | grep $contName | awk -F"\"*,\"*" '{print $1}')

sudo ./cpulimit -i -l $2 -p $contPid
