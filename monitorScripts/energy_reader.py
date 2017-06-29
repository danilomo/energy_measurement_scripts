#!/usr/bin/python -u

import sys
import json
import urllib2
import time
import numpy as np
import re		


now = lambda: int(round(time.time() * 1000))

t0 = float(now())
total = float(sys.argv[1])
samples = int(sys.argv[2])
tf = t0 + total * 1000.0
interval = total / float(samples)

mat = np.zeros((samples,13))

def readSensor(content, mat, i):
	dic = json.loads(content	.strip())

	values =  dic['sensor_values'][0]['values'][0]
	
	j = 0		
	for val in values:
		mat[i][j] = float(val['v'])
		j = j+1		

		
def printVals(i):		
	url = "http://10.93.182.126/statusjsn.js?_=1484231581352&components=18257"		
	req = urllib2.Request(url)
	res = urllib2.urlopen(req)
	content = res.read()
	readSensor(content, mat, i)

for i in range(0,samples-1):
	printVals(i)
	
	time.sleep(interval)
	
printVals(samples-1)

if((tf - now())/1000.0 > 0):
	time.sleep((tf - now())/1000.0)
	
np.set_printoptions(formatter={'float': lambda x: "{0:0.4f}".format(x)})

averages = np.mean(mat, axis=0)

#output = re.sub('[\[\]]', '', np.array_str(averages)).replace('\n', '')
output = re.sub('[\[\]]', '', np.array_str(mat[:,4])).replace('\n', '')
print 	' '.join(output.split())

#print "mat:"

#print mat[:,4]
#print ""
#
#print "averages: "
#print averages[4]

#print ""

#print "middle: " 
#print mat[int(samples)/2, 4]
#print ""

#print "last: "
#print mat[samples - 1, 4]
