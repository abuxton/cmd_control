#!/usr/bin/perl
####################################################################################
# This script checks for CPU IOwait using iostat
# Nagios exit codes: 2=Critical 1=Warning 0=OK 3=Unknown
####################################################################################

use Getopt::Std;
$validate = getopts("w:c:e:h", \%opt);

if (!$validate ){
&print_usage;
exit 3;
}

if (defined $opt{w}) {
        $warn=$opt{w};
} else {
        $warn="null";
}
if (defined $opt{c}) {
        $crit=$opt{c};
} else {
        $crit="null";
}
if (defined $opt{e}) {
        $err_code=$opt{e};
} else {
        $err_code="null";
}
if (defined $opt{h}) {
        &print_usage;
        exit 3;
}

if (($crit ne "null" && $crit !~ /^\d*\.?\d*$/) || ($warn ne "null" && $warn !~ /^\d*\.?\d*$/)) {
	print "The Critical/Warning thresholds should be numeric only \n";
	exit 3;
}

$rel=`cat /etc/redhat-release`;
if ($rel =~ /Pensacola/) {
        print "RHEL AS2.1 iostat, vmstat and sar utilities do not report cpu iowait";
        exit 0;
} elsif ($rel =~ /Taroon/) {
        $out=`/usr/bin/vmstat 1 2 | tail -1`;
        $iowait=(split/\s+/, $out)[16];
} else {
        $out=`/usr/bin/iostat -c 1 2 | tail -2 | head -1`;
        $iowait=(split/\s+/, $out)[4];
}


unless ($iowait =~ /\d+/) {
print "Unknown error ::${err_code}::critical=${crit} warning=${warn}:: Evaluvated output of command 'iostat' is not numeric. Can not proceed further\n";
exit 3;
}

######## Optional return results #########
if ($crit ne "null" && $iowait >= $crit) {
	print "CPU IOwait exceeds CRITICAL threshold\:\:$err_code\:\:warn=$warn,critical=$crit\:\:iowait=$iowait | iowait=$iowait \n";
	exit 2;
} elsif ($warn ne "null" && $iowait >= $warn) {
	print "CPU IOwait exceeds WARNING threshold\:\:$err_code\:\:warn=$warn,critical=$crit\:\:iowait=$iowait | iowait=$iowait \n";
	exit 1;
} else {
	print "CPU IOwait OK\:\:$err_code\:\:warn=$warn,critical=$crit\:\:iowait=$iowait | iowait=$iowait \n";
	exit 0;
} 

sub print_usage() {
	print "USAGE: $0 -w warn_threshold -c crit_threshold -e err_code \n";
	print "Both the thresholds cannot be null, please provide either warning or critical threholds \n";
	print "-e donotalarm if you do not want alarms \n";
}
