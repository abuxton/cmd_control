#!/usr/bin/perl
use Getopt::Std;
#################################################################################
# Script check_cmd_aiu.pl ("alarm if not matched")
# This script runs the command and compare to -s string option; matched=ok 
# unmatched=critical or warn
# Exit codes: 2=Critical 1=Warn 0=OK 3=Unknown
#################################################################################
getopts("wce:k:s:h", \%opt);
if (defined $opt{k}) {
	$cmd="$opt{k}";
	$res=`$cmd` || &alert_esm;
	chomp $res;
} else {
	&print_usage;
}
if (defined $opt{e}) {
	$err_code=$opt{e};
} else {
	$err_code="null";
}
if (defined $opt{h}) {
	&print_usage;
}
if (defined $opt{c}) {
	$crit="yes";
}
if (defined $opt{w}) {
	$warn="yes";
}
if (defined $opt{s}) {
	$str="$opt{s}";
	if ($crit eq "yes" && $res !~ /$str/i) {
        	print "No match CRITICAL::$err_code::warn=null,critical=$crit::result=$res | Status=2";
        	exit 2;
	} elsif ($warn eq "yes" && $res !~ /$str/i) {
		print "No match WARNING::$err_code::warn=$warn,critical=null::result=$res | Status=1";
		exit 1;
	} elsif ($res =~ /$str/i) {
		print "Pattern matched OK::$err_code::warn=$warn,critical=$crit::result=$res | Status=0";
		exit 0;
	}
} elsif (! defined $opt{s}) {
	print "none::$err_code::warn=$warn,critical=$crit::result=$res";
	exit 0;
} else {
	exit 3;
}

sub print_usage {
	print "USAGE check_cmd_ain [-w,-c] -e err_code -k command -s match_string";
	exit 0;
}
sub alert_esm {
        print "BROKEN MONITOR\:\:ESM00016\:\:\:\:Cannot run command $cmd | plugin=check_cmd_ain";
        exit 2;
}
exit 3;
