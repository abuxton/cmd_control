#!/usr/bin/python
"""
This is intended to be a script running on remote hosts and will be invoked via NRPE. 
It allows you to find out information about the network interfaces used on the remote host. 

The script can be invoked two ways - it can list the interfaces and IP addresses assigned to the interfaces or it can
print out health information for a specific interface. If the specified interface exists the connection count for tcp and
udp connections will be printed as well as various information surfaced by /proc/net/dev.

Note that this script does not call netstat because that command can take a very long time to run on a server with many thousand
connections.
"""
import commands
import re
import sys
import socket
import struct
from optparse import OptionParser



def parseProcNetDev():
	"""
	Parse the output of /proc/net/dev and return a dictionary of interfaces and health check data

	The return is a dictionary with keys of interface names. the value for each key is another dictionary which 
	stores key value pairs for the health check data belonging to that interface.
	"""

	val = commands.getoutput('cat /proc/net/dev')
	"""
	The format of /proc/net/dev may be inconsistent depending on the length of the interface name and values reported.

	Inter-|   Receive                                                |  Transmit
	 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
	    lo:18030528   70754    0    0    0     0          0         0 18030528   70754    0    0    0     0       0          0
	  eth0:24981052185 97128672    0    0    0     0          0         0 82591321762 21782116    0    0    0     0       0          0
	  sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
	"""

	"""
	split the output by line. if a line has ':' then it should be an interface reporting line.
	if the line is an interface health line then we can pull the interface name and the data
	"""
	val = val.split('\n')
	recvHeaders = []
	transHeaders = []
	interfaces = {}
	"""
	Build the list of column names so we can associate the values reported by the interface with a name
	"""
	for line in val:
		""" is this line a table / column header? """
		if '|' in line:
			""" assume Receive is before Transmit in this line """
			recvHeaders, transHeaders = line.split('|')[1:]
			p = re.compile(' *')
			recvHeaders = p.split(recvHeaders)
			transHeaders = p.split(transHeaders)
	"""
	Parse the interface health metric lines from the output
	"""
	for line in val:
		""" does this line report interface statistics?"""
		if ':' in line:
			interface, data = line.split(':')
			interface = interface.strip()
			"""
			the format of the line may have an arbitrary number (but assumed to be > 0) number of spaces.
			this will split the string in any place there is at least one space
			"""
			p = re.compile(' *')
			healthCheckValues = p.split(data)
			""" create a dictionary as the value for this interface to store the health check key value pairs """
			interfaces[interface] = {}
			"""
				append rv or tx to the names to identify them and set in Camelback Notation
			"""
			for index, r in enumerate(recvHeaders):
				interfaces[interface]['rv' + r.capitalize()] = healthCheckValues[index]
			
			recvHeaderOffset = len(recvHeaders)
			for index, t in enumerate(transHeaders):
				interfaces[interface]['tx' + t.capitalize()] = healthCheckValues[recvHeaderOffset + index]
	return interfaces	

def printAllInterfaces():
	"""
	print a newline seperated list of interface names and IPs
	if the IP for an interface does not exist 'None' should be printed
	"""
	interfaceNameIP = {}
	interfaces = parseProcNetDev()
	for i in interfaces:
		interfaceNameIP[i] = getInterfaceIP(i)
	for k,v in interfaceNameIP.items():
		print str(k) + ':' + str(v)

def getInterfaceIP(interfaceName):
	""" 
	get the IP belonging to an interface by parsing ifconfig
	"""
	cmd = '/sbin/ifconfig | grep -E -A 1 %s\w*' % interfaceName
	"""
	The output of cmd will look something like this

	eth0      Link encap:Ethernet  HWaddr 00:16:3E:33:98:DE
          inet addr:10.30.80.221  Bcast:10.30.83.255  Mask:255.255.252.0

	we are interested in getting the inet addr
	"""
	try:
		ipLine = commands.getoutput(cmd).split('\n')[1]
		ipAddress = ipLine.split('inet addr:')[1].split(' ')[0]
		return ipAddress
	except IndexError:
		return None



def printInterfaceHealthStatistics(interfaceName):
	"""
	print the health check values surfaced by /proc/net/dev for a given interface
	print the number of tcp and udp connections on that interface as well
	"""
	interfaces = parseProcNetDev()
	for iface,health in interfaces.items():
		if iface == interfaceName:
			#print iface,
			for name, value in health.items():
				print  name + ':' + value + '',

	printInterfaceConnectionCount(interfaceName)

def printInterfaceConnectionCount(interfaceName):
	"""
	return the tcp and udp connection count for all interfaces surfaced by /proc/net/tcp (and udp)
	"""
	ipAddress = getInterfaceIP(interfaceName)
	if ipAddress is None:
		return
	packedIP = socket.inet_aton(ipAddress)
	intIP = int(struct.unpack('<L', packedIP)[0])
	hexIP = hex(intIP).strip('0x')
	
	cmd = 'cat /proc/net/tcp'
	tcpConns = parseConnectionCount(hexIP, cmd)
	cmd = 'cat /proc/net/udp'
	udpConns = parseConnectionCount(hexIP, cmd)

	print 'tcpConns:%s udpConns:%s' % (tcpConns, udpConns)
	
def parseConnectionCount(hexIP, cmd):
	conns = 0
	output = commands.getoutput(cmd).split('\n')

	"""
		The output of proc/net/tcp looks something like this. we want to count the lines where the local_address 

	  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
	   0: 00000000:1622 00000000:0000 0A 00000000:00000000 00:00000000 00000000   213        0 4663677 1 ffff8800b03a1380 750 0 0 2 -1
	   1: 00000000:03E7 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 3840 1 ffff8800e1519900 750 0 0 2 -1
	   2: 00000000:006F 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 3709 1 ffff8800e1519300 750 0 0 2 -1
	   3: 00000000:0016 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 32404 1 ffff8800ddf43940 750 0 0 2 -1
	   4: 0100007F:0019 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 27979 1 ffff88006e8f18c0 750 0 0 2 -1
	   5: 00000000:975C 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 4053 1 ffff8800e1606780 750 0 0 2 -1
	   6: DD501E0A:E126 5817780A:0185 01 00000000:00000000 00:00000000 00000000     0        0 15786672 1 ffff8800bb633300 68 10 21 3 100
	   7: DD501E0A:EACA 5817780A:0185 01 00000000:00000000 00:00000000 00000000     0        0 14804720 1 ffff8800e1606d80 66 10 1 3 100
	   8: DD501E0A:EAC9 5817780A:0185 01 00000000:00000000 02:00071DDD 00000000     0        0 14804708 2 ffff8800e1518d00 67 10 1 3 100
	   9: DD501E0A:EACC 5817780A:0185 01 00000000:00000000 00:00000000 00000000     0        0 14804767 1 ffff8800e1607380 67 10 0 3 100
	  10: DD501E0A:EACD 5817780A:0185 01 00000000:00000000 00:00000000 00000000 85015        0 14804795 1 ffff8800e1607980 67 10 1 3 100
	  11: DD501E0A:F2A0 5817780A:0185 01 00000000:00000000 00:00000000 00000000 85015        0 15499269 1 ffff88008225ac80 68 10 1 3 100
	  12: DD501E0A:029A 2BD30E0A:0801 01 00000000:00000000 00:00000000 00000000     0        0 4045 3 ffff8800e1606180 54 10 17 3 58
	  13: DD501E0A:0016 92501E0A:CCE3 01 00000000:00000000 02:0003A06E 00000000     0        0 14804693 3 ffff8800e1518100 51 10 29 3 100
	"""
	for line in output:
		"""if this is not the column header line"""
		if ':' in line:
			ip = line.split(':')[1].strip()
			if ip.lower() == hexIP.lower():
				conns += 1
	return conns	




parser = OptionParser()
parser.add_option('-L', '--listInterfaces', dest='listInterfaces', action="store_true", help='List all interfaces on a remote host')
parser.add_option('-i', '--interface', dest='interface', help='interface to get information on')
(options, args) = parser.parse_args()

if options.listInterfaces and options.interface:
	print 'invalid argument combination. you can either list interfaces or request information on a single interface'
	sys.exit(1)

if options.listInterfaces:
	printAllInterfaces()
elif options.interface:
	printInterfaceHealthStatistics(options.interface)
else:
	print 'invalid arguments. see usage'
	sys.exit(1)

	
