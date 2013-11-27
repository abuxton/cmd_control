#!/usr/bin/perl
use IO::Socket::INET; 
use Getopt::Std;

getopts("wce:H:p:", \%opt);
if (defined $opt{p}) {
	$port="$opt{p}";
} else {
	&usage;
}
if (defined $opt{e}) {
	$err_code=$opt{e};
} else {
	$err_code="null";
}
if (defined $opt{w}) {
	$warn="yes";
} else {
	$warn="null";
}
if (defined $opt{c}) {
	$crit="yes";
} else {
	$crit="null";
}
$host="$opt{H}";

##### Get values #####
$sock = new IO::Socket::INET (PeerAddr => "$host",
			     PeerPort => "$port",
			     Proto => 'tcp');
			     Timeout => "5");
##### Optional results #####
if ((!defined $sock) && ($crit eq "yes")){
	print "Port $port is not responding CRITICAL\:\:$err_code\:\:warn=$warn,critical=$crit\:\:status=2 | $port=2"; 
	exit 2;
} elsif ((!defined $sock) && ($warn eq "yes")) {
	print "Port $port is not responding WARNING\:\:$err_code\:\:warn=$warn,critical=$crit\:\:status=1 | $port=1"; 
	exit 1;
} elsif ($sock) {
	close $sock;
	print "Port $port is open OK\:\:$err_code\:\:warn=$warn,critical=$crit\:\:status=0 | $port=0"; 
	exit 0;
}
if (!defined $sock) {
	print "Port $port is not responding:\:\:\:\:\:\:status=unresponsive | port=$port, status=2"; 
}
exit 3;

sub usage {
	print "USAGE: check_port -w|c -e err_code -H hostname -p port";
	exit 3;
}

