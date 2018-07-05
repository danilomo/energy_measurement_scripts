#!/usr/bin/env python

import sys
import json
import service_provider
import clutil
from clutil import Command

def loadDict(path):
    f = open(path)
    dic = json.load(f)
    f.close

    return dic
def print_out(x):
    for s in x:
        print(s.strip())

def get_node( machine, provider_file, provider ):
    dic = loadDict(provider_file)
    provider = service_provider.ServiceFactory(dic).create_provider(provider)
    provider.connect()
    node = provider.lookup_instance(machine)
    if(not node.isUp()):
        node.turnOn()
    node.waitServiceActive(22)
    node.openSSHSession()

    return node, provider

@Command
def instances( args, provider_file = "./configFiles/provider_config.json" ):
    dic = loadDict(provider_file)

    for key in dic:
        type_ = dic[key]['type']
        if "libvirt" == type_:
            instances = dic[key]['instances']

            for key in instances:
                print( key )

@Command
def address( args, provider_file = "./configFiles/provider_config.json", provider = "libvirt1" ):
    node, provider = get_node(args[0], provider_file, provider)
    print( node.getIPAddress() )

@Command
def command( args, provider_file = "./configFiles/provider_config.json", provider = "libvirt1" ):
    node, provider = get_node(args[0], provider_file, provider)
    x = node.sendSSHCommand(args[1])
    print_out(x)
    node.closeSSHSession()

@Command
def sendfile( args, provider_file = "./configFiles/provider_config.json", provider = "libvirt1" ):
    print(args)
    node, provider = get_node(args[0], provider_file, provider)
    node.sendFile(args[1], args[1])
    node.closeSSHSession()

@Command
def sendzip( args, provider_file = "./configFiles/provider_config.json", provider = "libvirt1" ):
    node, provider = get_node(args[0], provider_file, provider)
    node.sendFile(args[1], args[1])
    x = node.sendSSHCommand("unzip " +args[1])
    print_out(x)
    node.closeSSHSession()



    
clutil.execute()
