#!/usr/bin/python -u

import sys
import json

j = sys.stdin.read()

dic = json.loads(j.strip())

values =  dic['sensor_values'][0]['values'][0]

for i in values:
	print i['v'],
	
print
