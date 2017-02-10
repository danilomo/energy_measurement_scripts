from service_provider import *
import subprocess
import json
import time
import sys

class Experiment:

	def __init__(self, config_file, fac):
		f = open(config_file)
		dic = json.load(f)
		self._config = dic
		self._provider = fac.create_provider(dic["provider"])
		self._provider.connect()
		self._expConfig = "experiment_config.json"
		
	def prepareVirtualMachines(self):			
		
		instances = self._config["instances"]
		
		for inst in instances:
			with open("instances.txt", "a") as myfile:
			    myfile.write(str(self._provider.domainName(inst)) + "\n")			
		
		for inst in instances:
			node = self._provider.lookup_instance(inst)
			
			if( not node.isUp() ):
				node.turnOn()
				
		for inst in instances:
			node = self._provider.lookup_instance(inst)

			node.waitServiceActive(22)
			
		self.generateConfig()		
		
		for inst in instances:
			node = self._provider.lookup_instance(inst)
			
			node.openSSHSession()
			
			#node.sendFile(self._expConfig, "./.incron_files/config.json")
			#node.sendFile(self._expConfig, "./config.json")
			
			node.closeSSHSession()
			
			
	def startExperiment(self):
		comms = self._config["commands"]
		
		for key, command in comms.iteritems():
			node = self._provider.lookup_instance(key)
			
			node.openSSHSession()
			
			#command = self._config["command"]
			command = "nohup " + command + " > /dev/null 2>&1 &"
			
			print command + " Yup!" + key
			
			print node.sendSSHCommand( command )
			
			node.closeSSHSession()			

		
	def generateConfig(self):	
		baseTime = subprocess.check_output(["date", "-d", "+10 seconds"]).strip()
	
		dic = {
			"baseTime": baseTime,
			"command": self._config["command"],
			"samplingInterval": self._config["samplingInterval"],
			"experimentDuration": self._config["experimentDuration"]
		}
		
		with open(self._expConfig, "w") as text_file:
			text_file.write(json.dumps(dic))




#providerConfig = sys.argv[1]
#experimentConfig = sys.argv[2]

#fac = ServiceFactory(providerConfig)
#exp = Experiment(experimentConfig, fac)

#exp.startExperiment()
