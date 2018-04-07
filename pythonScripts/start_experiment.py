from service_provider import *
import subprocess
import json
import time
import sys
from experiment import Experiment

providerConfig = sys.argv[1]
config = sys.argv[2]

exp = Experiment(providerConfig, config)

exp.startExperiment()
