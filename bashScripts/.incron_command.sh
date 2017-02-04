#!/bin/bash

baseTime=$(jq '.baseTime' $1 | sed -e 's/^"//' -e 's/"$//' )
command=$(jq '.command' $1 | sed -e 's/^"//' -e 's/"$//' )
samplingInterval=$(jq '.samplingInterval' $1)
experimentDuration=$(jq '.experimentDuration' $1)

echo $baseTime
echo $command
echo $samplingInterval
echo $experimentDuration
