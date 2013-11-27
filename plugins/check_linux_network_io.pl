#!/usr/bin/perl
####################################################################################
# This script collects RXbytes/sec and TXbytes/sec used for bandwidth calculation
# Nagios exit codes: 2=Critical 1=Warning 0=OK 3=Unknown
####################################################################################
use Getopt::Std;
$validate =  getopts("i:h", \%opt);

if (!$validate){
&print_usage;
exit 3;
}

if (defined $opt{h}) {
	&print_usage;
	exit 0;
}
if (! defined $opt{i}) {
	print "Please specify the interface(s) \n";
	exit 0;
}
$args=$opt{i};
@args=split(/,/,$args);

foreach $int (@args) {
	$res=`sar -n DEV| grep Average |grep $int`;
	@arr=split(/\s+/,$res);
	$rx=$arr[4];
	$tx=$arr[5];
	if (($rx !~ /\d+/) || ( $tx !~ /\d+/ )){
	print "Command 'sar' not available or could not run 'sar' command or inteface $int not present \n";
	exit 3;
	}
	push(@rx_bps,"rx_$int=$rx");
	push(@tx_bps,"tx_$int=$tx");
}
print "Network IO::::::@rx_bps, @tx_bps | @rx_bps @tx_bps \n"; 

sub print_usage() {
	print "USAGE: $0 -i interfaces\n";
	print "Example: $0 -i eth0,eth1,qfe1\n";
	print "For bandwidth data collection, it is best to specify one interface per monitor.\n";
}
