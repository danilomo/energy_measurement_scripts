from service_provider import *
from subprocess import Popen
import subprocess
import json
import time
import sys
import sh
from qmp import QMP

global processes
processes = []


class Experiment:

    def __init__(self, providerConfig, config):

        def loadDict(path):
            f = open(path)
            dic = json.load(f)
            f.close

            return dic

        self._config = loadDict(config)
        self._providerConfig = loadDict(providerConfig)
        self._expConfig = "experiment_config.json"

        self.loadProviders()

    def prepareInstances(self):

        instances = self._config["instances"]

        for name, inst in instances.items():
            self.prepareInstance( name, inst )

        self.generateConfig()

    def loadProviders(self):

        providers = {}
        self._providers = providers
        
        for name, inst in self._config["instances"].items():
            if( self.getProvider(name) == "libvirt" ):
                factory = ServiceFactory( self._providerConfig )
                providers[name] = factory.create_provider(self._config["instances"][name]["provider"])
                providers[name].connect()

    def prepareInstance( self, name, inst ):
        if( self.getProvider( name ) == "libvirt" ):
            self.prepareLibvirtInstance( name, inst )

    def prepareLibvirtInstance( self, name, inst ):
        node = self._providers[name].lookup_instance( name )

        if( not node.isUp() ):
            node.turnOn()

        node.waitServiceActive(22)
        node.mapVCPU()

    def startExperiment(self):
        comms = self._config["commands"]

        for key, comm in comms.items():
            self.executeCommand( key, comm )

        for key, inst in self._config["instances"].items():
            
            if( self.getProvider(key) == "libvirt" ):
                
                if("cpulimit" in self._config["instances"][key]):                
                    limit = self._config["instances"][key]["cpulimit"]
                    self.setCPULimitVM( key, limit )

                if("iolimit" in self._config["instances"][key]):                
                    limit = self._config["instances"][key]["iolimit"]
                    self.setIOLimitVM( key, limit )

                if("cpushare" in self._config["instances"][key]):
                    share = self._config["instances"][key]["cpushare"]            
                    sh.virsh( "schedinfo", key, "--live", "cpu_shares=" + str( share ) )

                if("netlimit" in self._config["instances"][key]):
                    limit = self._config["instances"][key]["netlimit"]            
                    # todo - implement net limit for VM


    def setCPULimitVM( self, key, limit ):
        limit = self._config["instances"][key]["cpulimit"]
        time = self._config["experimentDuration"]
        
        cpulimcomm = sh.Command("./cpuLimitVM.sh").bake( str(time), key, limit )

        p = cpulimcomm( _bg = True )
        processes.append( p )

    def setIOLimitVM( self, key, limit ):
        qmp = QMP( key )
        
        device = qmp.query_block()[0]["device"]
        args = { "device": device, "bps": 0, "bps_rd": 0, "bps_wr": 0, "iops": 0, "iops_rd": 0, "iops_wr": 0 }
        limit = self._config["instances"][key]["iolimit"]
        args["iops"] = int(limit)

        res = qmp.block_set_io_throttle( args )
        print( res )

    def executeCommand( self, key, comm ):

        provider = self.getProvider(key)

        if( provider == "libvirt" ):
            self.executeLibvirtCommand( key, comm )
        elif( provider == "docker" ):
            self.executeDockerCommand( key, comm )
        elif( provider == "host" ):
            self.executeHostCommand( key, comm )

    def executeHostCommand( self, key, comm ):
        l = comm.split()
        name = l[0]
        args = l[1:]

        if("cpupin" in self._config["instances"][key]):
            cpupin = self._config["instances"][key]["cpupin"]
            command = sh.Command( "taskset" ).bake( "-c", cpupin, name, * args )
        else:
            command = sh.Command( name ).bake( * args )            

        p = command( _bg = True )
        pid = p.process.pid

        processes.append( p )

        if("cpulimit" in self._config["instances"][key]):
            limit = self._config["instances"][key]["cpulimit"]            
            cpulimitcomm = sh.Command( "./cpulimit" ).bake( "-i", "-l", str(limit), "-p", str(pid) )            
            p2 = cpulimitcomm( _bg = True )

            processes.append( p2 )




    def executeDockerCommand( self, key, comm ):
        pass

    def executeLibvirtCommand( self, key, comm ):
        provider = self._providers[key]

        node = provider.lookup_instance(key)
        node.openSSHSession()
        command = "nohup " + comm + " > /dev/null 2>&1 &"
        node.sendSSHCommand( command )
        node.closeSSHSession()
            
    def getProvider( self, instname ):
        prov = self._config["instances"][instname]["provider"]
        if( prov == "host" ):
            return prov
        else:
            return self._providerConfig[prov]["type"]

    def generateConfig(self):
        baseTime = subprocess.check_output(["date", "-d", "+10 seconds"]).strip().decode("utf-8")

        dic = {
            "baseTime": baseTime,
            "samplingInterval": self._config["samplingInterval"],
            "experimentDuration": self._config["experimentDuration"]
        }

        with open(self._expConfig, "w") as text_file:
            text_file.write(json.dumps(dic))
