#!/usr/bin/perl
#######################################################################################
# This script checks Dom0 Total CPU Utilization using xentop command
# Nagios exit codes: 2=Critical 1=Warning 0=OK 3=Unknown
#######################################################################################
use Getopt::Std;
getopts("w:c:e:h", \%opt);
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
	if ($err_code eq "donotalarm") {
                print "Do Not Alarm";
                exit 0;
        }
} else {
	$err_code="null";
}
if (defined $opt{h}) {
	&print_usage;
	exit 0;
}
######### Get values #########
$out=`sudo /usr/sbin/xentop -b -i 1 | grep CPUs:`;

if ($out !~ /\d+/) {
print "Could not run 'sudo /usr/sbin/xentop -b -i 1' Sucessfully. Check if sudo permissions exists for user nagios.\n";
exit 3;
}


$cpus=(split/\s+/, $out)[8];
@doms=`sudo /usr/sbin/xm list |grep -vi name |awk '{print $1}'`;

if (! @doms ){
print "Could not run 'sudo /usr/sbin/xm list' Sucessfully. Check if sudo permissions exists for user nagios.\n";
exit 3;
}


@res=`sudo /usr/sbin/xentop -b -i 3`;

if (! @res ){
print "Could not run 'sudo /usr/sbin/xentop -b -i 3' Sucessfully. Check if sudo permissions exists for user nagios.\n";
exit 3;
}

foreach (@doms) {
        $dom = (split/\s+/, $_)[0];
        foreach $line (@res) {
                next if ($line !~ /$dom/);
                if ($line =~ /Domain/i) {
                        $cpu = (split/\s+/, $line)[4];
                } else {
                        $cpu = (split/\s+/, $line)[3];
                }

                $tot_usage += $cpu;
        }
}
### Average total cpu usage
### First iteration is always 0 so we are dividing by 2 instead of 3 ###
$avg_usage = $tot_usage / 2;

### Divide total usage by total cpu percent
$usage_percent = sprintf("%d", ($avg_usage/$cpus));

######### Optional return results #########
if ( $crit ne "null" && $usage_percent >= $crit ) {
        print "Usage per CPU passed Critical threshold\:\:$err_code\:\:warn=$warn,critical=$crit\:\:number_of_cpus=$cpus,per_cpu_usage=$usage_percent% | per_cpu_usage=$usage_percent \n";
        exit 2;
} elsif ( $warn ne "null" && $usage_percent >= $warn ) {
        print "Usage per CPU passed Warning threshold\:\:$err_code\:\:warn=$warn,critical=$crit\:\:number_of_cpus=$cpus,per_cpu_usage=$usage_percent% | per_cpu_usage=$usage_percent \n";
        exit 1;
} else {
        print "Usage per CPU OK\:\:$err_code\:\:warn=$warn,critical=$crit\:\:number_of_cpus=$cpus,per_cpu_usage=$usage_percent% | per_cpu_usage=$usage_percent \n";
        exit 0;
}

sub print_usage() {
        print "USAGE: $0 -w warn_threshold_% -c crit_threshold_% -e err_code \n";
        print "-e donotalarm if you do not want alarms \n";
}
