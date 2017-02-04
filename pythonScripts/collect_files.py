from service_provider import *
import subprocess
import json
import time
import sys

providerConfig = sys.argv[1]
experimentConfig = sys.argv[2]

fac = ServiceFactory(providerConfig)

f = open(experimentConfig)
dic = json.load(f)

print dic

instances = dic["instances"]

prov = fac.create_provider(dic["provider"])
prov.connect()

for i in instances:
	node = prov.lookup_instance(i)
	node.openSSHSession()
	node.getFile( "./logFiles/log_io.txt", "./logFiles/log_" + i + "_io.txt");
	node.getFile("./logFiles/log_net.txt", "./logFiles/log_" + i + "_net.txt");
	node.closeSSHSession()
	
	

