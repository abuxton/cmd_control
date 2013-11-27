#!/usr/bin/perl
use Getopt::Std;
#################################################################################
# Script check_cmd.pl has 3 options: 1)alarm if matched 2)alarm if not matched
# and 3)return result as is 
# Note: Only either critical or warning alert will be sent, not both
# Exit codes: 2=Critical 1=Warn 0=OK 3=Unknown
#################################################################################
getopts("o:e:wck:s:h", \%opt);
if (defined $opt{k}) {
	$cmd="$opt{k}";
	$cmd=~s/cobw3b/\|/g;
	$res=`$cmd`; 
	$retval=`echo $?`;
	chomp $res;
	$res=~s/\|/cobw3b/g;
}
if (defined $opt{o}) {
	$oper="$opt{o}";
}
if (defined $opt{e}) {
	$err_code=$opt{e};
} else {
	$err_code="null";
}
if (defined $opt{c}) {
        $crit="yes";
} else {
	$crit="null";
}
if (defined $opt{w}) {
        $warn="yes";
} else {
	$warn="null";
}
if (defined $opt{h}) {
	&print_usage;
}
if (defined $opt{s}) {
	$str="$opt{s}";
	if ($oper eq "matched") {
		if ($crit eq "yes" && $res=~/$str/i) {
			print "Content Matched CRITICAL\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=2";
	        	exit 2;
        	} elsif ($warn eq "yes" && $res =~ /$str/i) {
                	print "Content Matched WARNING\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=1";
                	exit 1;
        	} elsif ($res !~ /$str/i) {
                	print "No Match OK\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=0";
                	exit 0;
		} elsif ($res =~ /$str/i) {
			print "CRITICAL - Matched but not alerting\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=0";
			exit 0; 	
		}
	} 
	if ($oper eq "not_matched") {
		if ($crit eq "yes" && $res !~/$str/i) {
			print "Content not matched CRITICAL\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=2";
			exit 2;
		} elsif ($warn eq "yes" && $res !~/$str/i) {
                        print "Content not matched WARNING\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=1";
                        exit 1;
		} elsif ($res =~ /$str/i) {
			print "Matched OK\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=0";
                        exit 0;
		} elsif ($res !~ /$str/i) {
			print "CRITICAL - Not matched but not alerting\:\:$err_code\:\:warn=$warn,critical=$crit\:\:result=$res,content match=$str | Status=0";
			exit 0;
		}
	}
} elsif (! defined $opt{s}) {
	if ($retval != 0) {
		print "CRITICAL\:\:$err_code\:\:warn=null,critical=null\:\:result=$res,content match=null,exit status=$retval | Status=$retval";
		exit 2;
	} else {
		print "OK\:\:$err_code\:\:warn=null,critical=null\:\:result=$res,content match=null,exit status=$retval | Status=$retval";
		exit 0;
	}
}

sub print_usage {
	print "USAGE: check_cmd -o [matched|not_matched] -w|-c -e err_code -k command -s string\n";
	print "Description: This script runs a command and has 3 optional results:\n";
	print "1) alert if matched [-o matched] 2) alert if not matched [-o not_matched], and 3) return result as is\n";
	print "Note: Only either critical or warning alert will be sent, not both\n";
	print "-e donotalarm if you do not want alarms";
	exit 0;
}
sub alert_esm {
	print "BROKEN MONITOR\:\:ESM00016\:\:\:\:Cannot run command | plugin=check_linux_command";
	exit 2;
}
exit 3;
