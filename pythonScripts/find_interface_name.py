from service_provider import *
import subprocess
import json
import time
import sys

providerConfig = sys.argv[1]
providerName = sys.argv[2]
instance = sys.argv[3]

fac = ServiceFactory(providerConfig)
provider = fac.create_provider(providerName)

provider.connect()

node = provider.lookup_instance(instance)

print node.getNetworkInterface()
