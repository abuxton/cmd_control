#!/usr/bin/perl
##################################################################################
# This script checks for Load Average using command uptime
# Nagios exit codes: 2=Critical 1=Warning 0=OK 3=Unknown
##################################################################################
use strict;
use Getopt::Std;

my (%opt, $uptime, $numcpus, $validate);
my $message = 'CPU Load Avg';
my @statusdesc = qw(OK WARNING CRITICAL UNKNOWN);

$validate = getopts("w:c:e:hr", \%opt);

if (!$validate){
&print_usage;
exit 3;
}

if ( defined($opt{h}) or (!defined($opt{'w'}) and !defined($opt{'c'}))) {
	&print_usage;
	exit 0;
}

if ($opt{'w'} !~ /^\d*\.?\d*$/) {
	print "Warning threshold should be an integer.\n";
	&print_usage;
	exit 3;
}

if ($opt{'c'} !~ /^\d*\.?\d*$/) {
	print "Critical threshold should be an integer.\n";
	&print_usage;
	exit 3;
}

if ( defined($opt{'w'}) and defined($opt{'c'}) and $opt{'w'} >= $opt{'c'} ) {
	print "Warning threshold should be lower than Critical\n";
	&print_usage;
	exit 3;
}



######## Get load #########
my $uptime = `/usr/bin/uptime 2>&1`;
if ($? >> 8 != 0) {
	$uptime =~ s/[\r\n]/ /g;
	printf "$message UNKNOWN:: Call to `/usr/bin/uptime` failed! "
		."(output: '$uptime', exitvalue: %d)\n", $? >> 8;
	exit 3;
}
$uptime =~ m/average:\s+([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)/;
my ($load1, $load5, $load15) = ($1, $2, $3);


######## Get Num CPUs if necessary #########
if (defined($opt{'r'})) {
	$numcpus = `/bin/cat /proc/cpuinfo|/bin/grep '^processor'|/usr/bin/wc -l`;
	if ($? >> 8 != 0) {
		$numcpus =~ s/[\r\n]/ /g;
		printf "$message UNKNOWN:: Call to `/bin/cat /proc/cpuinfo | "
			."/bin/grep '^processor' | /usr/bin/wc -l`"
			." failed! (output: '$numcpus', exitvalue: %d)\n", $? >> 8;
		exit 3;
	}
	
	chomp($numcpus);
	for ($load1, $load5, $load15) {
		$_ = sprintf("%0.2f", $_/$numcpus);
	}
	
	$message .= ' (Per CPU)';
}

unless ($load5 =~ /\d+/) {
print "Unknown error ::$opt{'e'}::critical=$opt{'c'} warning=$opt{'w'}:: Evaluvated output of command 'uptime' is not numeric. Can not proceed further\n";
exit 3;
}


my ($status);
if (defined($opt{'c'}) and $load5 > $opt{'c'}) {
	$status = 2;
}
elsif (defined($opt{'w'}) and $load5 > $opt{'w'}) {
	$status = 1;
}
else {
	$status = 0;
}

print "$message $statusdesc[$status]\:\:$opt{'e'}\:\:"
	."warn=$opt{'w'},critical=$opt{'c'}\:\:"
	."load1=$load1,load5=$load5,load15=$load15 |"
	." load1=$load1 load5=$load5 load15=$load15 \n";

exit $status;

sub print_usage() {
	print "USAGE: $0 -w warn_threshold -c crit_threshold -e err_code\n";
	print "  -e donotalarm if you do not want alarms\n";
	print "  -r divides load by # of CPU cores\n";
	print "  -h This help. \n";
}

