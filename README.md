###### Introduction

A set of bash/python scripts for experimenting with virtual machines and measuring energy.

It employs a python API for handling virtual machines (turning on/off, locating VM by name, sending SSH commands,
sending files via SCP, etc). The API is abstract and there is a concrete implementation that uses KVM/Qemu as provider
of VMs. A implementation for OpenStack was started, but it was not finished. It adopts a JSON configuration file to
specify the instances to being used, and the connection parameters.

The monitor scripts are synchronized with a few miliseconds of difference between the samples. It uses some sysstat commands (mpstat, sysstat), iotop,
and /proc/net/dev to measure CPU (host and VMs), IO, memory, and network. The energy measurement is performed by sending HTTP requests
to the "Expert Power Control" device, plugged between the host and the energy supply, and connected to the local network.



###### HOW TO USE:

1. Clone this repository
2. Modify the config files
3. Invoke "./startExperiment.sh"
4. Wait the experiment to finish and collect the log files







###### References

* http://www.distrelec.ch/de/power-control-1103-steuerbare-steckdose-fuer-tcp-ip-gude-1103/p/11060923
