#!/usr/bin/python -u

import sys
import json

fileName = sys.argv[1]

with open(fileName, 'r') as myfile:
    data = myfile.read().replace('\n', '')
    
    j = json.loads(data)
    
    for i in j:
    	sys.stdout.write(i['name'] + " " )
    
    sys.stdout.flush()
    print ""
