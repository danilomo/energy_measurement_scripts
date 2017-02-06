from service_provider import *
import subprocess
import json
import time
import sys
from experiment import Experiment

providerConfig = sys.argv[1]
experimentConfig = sys.argv[2]

fac = ServiceFactory(providerConfig)
exp = Experiment(experimentConfig, fac)

exp.prepareVirtualMachines()
