#!/bin/bash

function loop {
    while :
    do
        wget -O /dev/null -o /dev/null http://foobar.zdv.uni-mainz.de:8000/suse.iso
    done
}

export -f loop

timeout $1 bash -c loop
