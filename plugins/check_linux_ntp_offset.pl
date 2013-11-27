#!/usr/bin/perl
###################################################################################
# This script runs ntpdc -c peers and checks for ntp offset
# Nagios exit codes: 2=Critical 1=Warning 0=OK 3=Unknown
###################################################################################
use Getopt::Std;
$validate = getopts("w:c:e:h", \%opt);

if (!$validate){
	&print_usage;
	exit 3;
}

if (defined $opt{e}) {
        $err_code=$opt{e};
} else {
        $err_code="null";
}
if (defined $opt{c}) {
        $crit=$opt{c};
} else {
        $crit="null";
}
if (defined $opt{w}) {
        $warn=$opt{w};
} else {
        $warn="null";
}
if (defined $opt{h}) {
        &print_usage;
        exit 0;
}

if (($crit ne "null" && $crit !~ /^\d*\.?\d*$/) || ($warn ne "null" && $warn !~ /^\d*\.?\d*$/)) {
        print "The Critical/Warning thresholds should be numeric only \n";
        exit 3;
}


if (($crit ne "null") && ($warn ne "null") && ($warn >= $crit)) {
        print "Warning threshold should be lower than critical threshold \n";
        exit 0;
}

######### Get values ##########
$check1=system("ls /usr/sbin/ntpdc > /dev/null");
if ($check1 != 0) {
        print "BROKEN MONITOR - Command /usr/sbin/ntpdc used for this plugin is not available \n";
        exit 3;
}
@out=`/usr/sbin/ntpdc -c peers |grep -v === `;


foreach $li (@out){
	if ($li =~ /^\*/){
		$offset=(split/\s+/, $li)[6];
		$opmode = 'Current sync';
		last ;
	}elsif ($li =~ /^\=/){
		$offset=(split/\s+/, $li)[6];
		$opmode = 'Client Mode';
		last ;
	}
}

unless ($offset =~ /\d+/) {
	print "CRITICAL NTP error ::${err_code}::critical=${crit} warning=${warn}:: NTP Sync Failed\n";
	exit 2;
}

######## Optional return results #########
if ($crit ne "null" && abs($offset) >= $crit) {
        print "NTP offset passed critical threshold - Mode=$opmode \:\:$err_code\:\:warn=$warn,critical=$crit\:\:offset=$offset | offset=$offset \n";
        exit 2;
} elsif ($warn ne "null" && abs($offset) >= $warn) {
        print "NTP offset passed warning threshold - Mode=$opmode \:\:$err_code\:\:warn=$warn,critical=$crit\:\:offset=$offset | offset=$offset \n";
        exit 1;
} else { 
        print "NTP offset OK - Mode=$opmode \:\:$err_code\:\:warn=$warn,critical=$crit\:\:offset=$offset | offset=$offset \n";
        exit 0;
}

sub print_usage() {
        print "USAGE: $0 -w warn_threshold -c crit_threshold -e err_code";

}
exit 3;
