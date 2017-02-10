from service_provider import *
import subprocess
import json	

fac = ServiceFactory("../configFiles/provider_config.json")
prov = fac.create_provider("libvirt1")
prov.connect()
node = prov.lookup_instance("ubuntu02")

print node._node.vcpuPinInfo()[0]
#print help(node._node.pinVcpu)


