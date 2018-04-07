from service_provider import *
from subprocess import Popen
import subprocess
import json
import time
import sys

class Experiment:

	def __init__(self, providerConfig, config):

		def loadDict(path):
			f = open(path)
			dic = json.load(f)
			f.close

			return dic

		self._config = loadDict(config)
		self._providerConfig = loadDict(providerConfig)

		provider = self._config["provider"]

		if(self._providerConfig[provider]["type"] == "libvirt"):
			factory = ServiceFactory(providerConfig)
			self._provider = factory.create_provider(self._config["provider"])
			self._provider.connect()

		self._expConfig = "experiment_config.json"

	def prepareInstances(self):
		provider = self._config["provider"]

		if(self._providerConfig[provider]["type"] == "libvirt"):
			self._prepareLibvirtInstances()
		elif(self._providerConfig[provider]["type"] == "docker"):
			self._prepareDockerContainers()

		self.generateConfig()

	def _prepareLibvirtInstances(self):
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
			node.mapVCPU()

	def _prepareDockerContainers(self):
		pass


	def startExperiment(self):
		provider = self._config["provider"]

		if(self._providerConfig[provider]["type"] == "libvirt"):
			self._startLibvirtExperiments()
		elif(self._providerConfig[provider]["type"] == "docker"):
			self._startDockerExperiments()


	def _startLibvirtExperiments(self):
		comms = self._config["commands"]

		for key, command in comms.iteritems():
			node = self._provider.lookup_instance(key)
			print("Sending command.")
			node.openSSHSession()

			command = "nohup " + command + " > /dev/null 2>&1 &"

			node.sendSSHCommand( command )

			print("Command sent.")

			node.closeSSHSession()

	def _startDockerExperiments(self):
	    comms = self._config["commands"]
            provider = self._config["provider"]

            for key, command in comms.iteritems():
                lCpu = self._providerConfig[provider]["instances"][key]["cpu_pin"]
                cpuAffinity = str([i[0] for i in enumerate(lCpu) if i[1] == 1 ]).replace("[", "").replace("]", "").replace(" ", "")
                imageName = self._providerConfig[provider]["instances"][key]["image_name"]

                dockerCommand = "docker run -d=true --name=%s --rm --cpuset-cpus=%s %s " % (key, cpuAffinity, imageName)
                dockerCommand = dockerCommand + command

                print(dockerCommand)

                p = Popen( dockerCommand.split() )

                if( "cpu_limit" in self._providerConfig[provider]["instances"][key] ):
                    cpuLimit = self._providerConfig[provider]["instances"][key]["cpu_limit"]
                    cpuLimitCommand = "./cpuLimitContainer.sh %s %s" % (key, cpuLimit)
                    pLimit = Popen( cpuLimitCommand.split() )



	def generateConfig(self):
		baseTime = subprocess.check_output(["date", "-d", "+10 seconds"]).strip()

		dic = {
			"baseTime": baseTime,
			"samplingInterval": self._config["samplingInterval"],
			"experimentDuration": self._config["experimentDuration"]
		}

		with open(self._expConfig, "w") as text_file:
			text_file.write(json.dumps(dic))
