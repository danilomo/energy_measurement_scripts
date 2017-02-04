#!/usr/bin/python -u

from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
import libcloud.security
import paramiko
from scp import SCPClient
import socket

import libvirt

import json
import time
import os, platform

libcloud.security.VERIFY_SSL_CERT = False

def ping(host):
	"""
	Returns True if host responds to a ping request
	"""
	# Ping parameters as function of OS
	ping_str = "-n 1" if  platform.system().lower()=="windows" else "-c 1"

	# Ping
	return os.system("ping " + ping_str + " " + host + " > /dev/null" ) == 0

class ServiceProvider:

	def __init__(self):
		self._nodes = {}
		pass

	def connect(self):
		raise NotImplementedError()
		
	def launch_instance(self, name):
		raise NotImplementedError()
		
	def kill_instance(self, name):
		raise NotImplementedError()
		
	def lookup_instance(self, name):
		raise NotImplementedError()
		
class LibvirtProvider(ServiceProvider):

	def __init__(self, dic):
		self._dic = dic
		self._domains = {}

	def connect(self):
		parameters = self._dic["parameters"]
		self._conn = libvirt.open(parameters["url"])
		return self._conn
		
	def launch_instance(self, name):
		n = self.lookup_instance(name)
		n._node.create()
		
	def lookup_instance(self, name):
		domain_name = self._get_domain_name(name)
		uname = self._get_instance_attribute(name, "user_name")
		pwd = self._get_instance_attribute(name, "password")
		
		node = self._conn.lookupByName(domain_name)		
		
		n = LibvirtNode(name, node)
		n._uname = uname
		n._pwd = pwd
		return n
		
	def domainName(self, name):
		return self._get_domain_name(name)
		
	def kill_instance(self, name):
		domain_name = self._get_domain_name(name)
		node = self._domains[domain_name]
		node.shutdown()
	
	def _get_domain_name(self, name):
		return self._get_instance_attribute(name, "domain_name")
		
	def _get_instance_attribute(self, name, attribute):
		return self._dic["instances"][name][attribute]	
		
class OpenStackProvider(ServiceProvider):
	def __init__(self, dic):
		self._dic = dic

	def connect(self):
		parameters = self._dic["parameters"]					

		OpenStack = get_driver(Provider.OPENSTACK)
		
		self._driver = OpenStack(
			parameters["user"], parameters["password"],
			ex_force_auth_version='2.0_password',
			ex_force_auth_url= parameters["url"],
			ex_tenant_name=parameters["tenant_name"],
			ex_force_service_name='nova',
			ex_force_service_region=parameters["region"]
		)
		
		images = self._driver.list_images()
		sizes = self._driver.list_sizes()
		
		self._imagesDic = {}
		self._sizesDic = {}
		
		for i in images:
			self._imagesDic[i.name] = i
			
		for s in sizes:
			self._sizesDic[s.name] = s
			
		return self._driver
		
	def launch_instance(self, name):
		imageName = self._dic["instances"][name]["image"]
		sizeName = self._dic["instances"][name]["size"]
		
		im = self._imagesDic[imageName]
		si = self._sizesDic[sizeName]

		node = self._driver.create_node(name=name, image=im, size=si)	
		return node		
		
class ServiceFactory:

	def __init__(self, config_file):
		f = open(config_file)
		dic = json.load(f)
		self._config = dic
		pass
	
	def create_provider(self, name):
		dic = self._config[name]
		type = dic["type"]
		
		if(type == "libvirt"):
			return LibvirtProvider(dic)
		elif(type == "openstack"):
			return OpenStackProvider(dic)
		
			
		return None
		
class Node:
	def __init__(self):
		self._ssh = None
		pass		
				
	def getName(self):
		raise NotImplementedError()
		
	def isUp(self):
		raise NotImplementedError()

	def getId(self):
		raise NotImplementedError()
		
	def kill(self):
		raise NotImplementedError()
		
	def reboot(self):
		raise NotImplementedError()
		
	def getIPAddress(self):
		raise NotImplementedError()
		
	def openSSHSession(self):
		
		ip = self.getIPAddress()
		
		if( ip is None ):
			#raise error
			return
		
		self._ssh = paramiko.SSHClient()
		self._ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
		self._ssh.connect(ip, username=self._uname, password=self._pwd)
		self._scp = SCPClient(self._ssh.get_transport())
		
	def sendSSHCommand(self, command):
		ssh_stdin, ssh_stdout, ssh_stderr = self._ssh.exec_command(command)				
		return ssh_stdout.readlines()
		
	def sendSudoSSHCommand(self, command):
		sudoCommand = "echo '%s' | sudo -S %s" % (self._pwd, command)
		return self.sendSSHCommand( sudoCommand )
		
	def closeSSHSession(self):
		self._ssh.close()
		self._ssh = None
		
	def ping(self):
		ip = self.getIPAddress()
		
		if( ip is None ):
			return False

		return ping(ip)
		
	def waitNetworked(self):	
		while( not self.ping() ):
			#print "Ping..."
			time.sleep(1)
			
	def checkIsServiceActive(self, port):
		if( not self.ping() ):
			return False			
	
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.settimeout(2)

		result = sock.connect_ex((self.getIPAddress(),port))
		
		return result == 0
					
	def waitServiceActive(self, port):
		while( not self.checkIsServiceActive(port) ):
			#print "Ping service..."
			time.sleep(1)		
			
	def sendFile(self, fileName, destPath):
		return self._scp.put(fileName, destPath)
		
	def getFile(self, fileName, destPath):
		return self._scp.get(fileName, destPath)
								
class LibvirtNode(Node):

	def __init__(self, name, node):
		self._name = name	
		self._node = node
		self._id = name	
		
	def getName(self):
		return self._name

	def getId(self):
		return self._node.UUIDString()
		
	def kill(self):
		self._node.shutdown()
		
	def reboot(self):
		self._node.reboot()
		
	def turnOn(self):
		self._node.create()
		
	def getIPAddress(self):			
	
		if( not self._node.isActive() ):
			return None
	
		dic = self._node.interfaceAddresses(0)
		
		if( not any(dic) ):
			return None			
		
		firstKey = dic.keys()[0]
		
		return dic[firstKey]["addrs"][0]["addr"]
		
	def getNetworkInterface(self):			
	
		if( not self._node.isActive() ):
			return None
	
		dic = self._node.interfaceAddresses(0)
		
		if( not any(dic) ):
			return None			
		
		firstKey = dic.keys()[0]
		
		return firstKey		
		
	def isUp(self):
		return self._node.isActive()
