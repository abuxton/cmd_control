#!/usr/bin/perl

$length = 0;
@df = `df -i | grep -v Filesystem`;
foreach $arg (0..$#ARGV) {
	($inode,$warn,$crit,$errcode) = split(/,/, $ARGV[$arg]);
	foreach (@df) {
		@line = split;
		$fs = "local" if ($#line == 5);
                $fs = "mount" if ($#line == 4);
	        if ($fs eq "local") {
                	$tot = sprintf("%d",($line[1]/1000));
                	$used = sprintf("%d",($line[2]/1000));
                	$avail = sprintf("%d",($line[3]/1000));
                	$used_p = $line[4];
                	$used_p =~ s/%//;
                	$disk = $line[5];
        	} elsif ($fs eq "mount") {
                	$tot = sprintf("%d",($line[0]/1000));
                	$used = sprintf("%d",($line[1]/1000));
                	$avail = sprintf("%d",($line[2]/1000));
                	$used_p = $line[3];
                	$used_p =~ s/%//;
                	$disk = $line[4];
        	}
		if ($inode eq $disk) {
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
			$exit = "$rc\:\:DISK INODE $status\:\:$errcode\:\:$warn,$crit\:\:$inode used%=$used_p,total=$tot K,used=$used K,avail=$avail K\:\:$inode=$used";
		        push(@print, "$exit\n");
			last;
		} else {
			$status = "NO MATCH";
		}
 	}
	if ($status eq "NO MATCH") {
		$exit = "0\:\:$inode is not a file system\:\:$errcode";
		push(@print, "$exit\n");
	}
        $length += length($exit);
        if ($length >= 975) {
                $exit = "Exceeding 1024 characters limit";
                push(@print, "$exit\n");
        }
}
print "@print";
