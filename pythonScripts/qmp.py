import sh
import json
import clutil
from clutil import Command

class QMP:

    _comands_with_hyphen = set([ "inject_nmi", "dump_guest_memory", "blockdev_snapshot_sync",
                                 "human_monitor_command", "query_events", "query_chardev", "query_block",
                                 "query_blockstats", "query_cpus", "query_pci"
    ])

    def __init__(self,domain_name, url = None):
        self.domain_name = domain_name

        if url and isinstance(url, str):
            self.virsh = sh.virsh.bake("-c", url, "qemu-monitor-command", domain_name, "--pretty")
        else:
            self.virsh = sh.virsh.bake("qemu-monitor-command", domain_name, "--pretty")
            

    def __getattr__(self, name):
        
        dct = {
            "execute": name.replace("_", "-") if name in QMP._comands_with_hyphen else name
        }
        
        def inner( arguments = None ):
            nonlocal self
            nonlocal dct
            if arguments and isinstance( arguments, dict ):
                dct["arguments"] = arguments

            cli_args = json.dumps(dct)

            p = self.virsh( cli_args )
            output = p.stdout.decode("utf-8")
            dict_output = json.loads(output)

            if "error" in dict_output:
                raise  ValueError('Error found: ' + dict_output["error"]["desc"] )

            return dict_output["return"]

        return inner

def get_block_device_name(qmp, index = 0):
    return qmp.query_block()[index]["device"]

def set_io_throttle( qmp, device, **kvargs ):
    
    defaults = { "bps": 0, "bps_rd": 0, "bps_wr": 0, "iops": 0, "iops_rd": 0, "iops_wr": 0 }
    args = { "device": device }
        
    for key in defaults:
        args[key] = kvargs[key] if key in kvargs else defaults[key]

    print(args)

    qmp.block_set_io_throttle( args )

@Command
def blockname( args ):
    qmp = QMP(args[0])
    print(get_block_device_name(qmp))

@Command
def query( args ):
    qmp = QMP(args[0])
    print(json.dumps(qmp.query_block(), indent = 2))

@Command
def setiot(args):
    qmp = QMP(args[0])
    device = get_block_device_name(qmp)
   
    lim = int(args[1])
    print("Limit: %d" % lim)

    set_io_throttle( qmp, device, iops = lim )

clutil.execute()
