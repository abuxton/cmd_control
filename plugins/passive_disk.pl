#!/usr/bin/perl

$length = 0;
@df = `df -k | grep -v Filesystem`;
foreach $arg (0..$#ARGV) {
	($partition,$warn,$crit,$errcode) = split(/,/, $ARGV[$arg]);
	foreach (@df) {
		@line = split;
		$fs = "local" if ($#line == 5);
                $fs = "mount" if ($#line == 4);
	        if ($fs eq "local") {
                	$tot = sprintf("%d",($line[1]/1024));
                	$used = sprintf("%d",($line[2]/1024));
                	$avail = sprintf("%d",($line[3]/1024));
                	$used_p = $line[4];
                	$used_p =~ s/%//;
                	$disk = $line[5];
        	} elsif ($fs eq "mount") {
                	$tot = sprintf("%d",($line[0]/1024));
                	$used = sprintf("%d",($line[1]/1024));
                	$avail = sprintf("%d",($line[2]/1024));
                	$used_p = $line[3];
                	$used_p =~ s/%//;
                	$disk = $line[4];
        	}
		if ($partition eq $disk) {
        		if ($crit ne "null" && $used_p > $crit) {
                		$status = "CRITICAL";
                		$rc = "2";
        		} elsif ($warn ne "null" && $used_p > $warn) {
                		$status = "WARNING";
                		$rc = "1";
        		} elsif ($used_p <= $crit || $used_p <= $warn) {
                		$status = "OK";
                		$rc = "0";
        		}
			$exit = "$rc\:\:DISK SPACE $status\:\:$errcode\:\:$warn,$crit\:\:$partition used%=$used_p,total=$tot mb,used=$used mb,avail=$avail mb\:\:$partition=$used";
		        push(@print, "$exit\n");
			last;
		} else {
			$status = "NO MATCH";
		}
 	}
	if ($status eq "NO MATCH") {
		$exit = "0\:\:$partition is not a file system\:\:$errcode";
		push(@print, "$exit\n");
	}
	$length += length($exit);
	if ($length >= 975) {
		$exit = "Exceeding 1024 characters limit";
		push(@print, "$exit\n");
	}
}
print "@print";
