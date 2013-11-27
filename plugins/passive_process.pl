#!/usr/bin/perl

$length = 0;
foreach $arg (0..$#ARGV) {
        ($process, $alert, $threshold, $above_or_below, $errcode) = split(',', $ARGV[$arg]);
	$process =~ (s/%/ /);
	$val = `ps aux | grep "$process" |grep -v grep |grep -v passive | awk '{CPU += \$3} {MEM += \$4} {COUNT ++}  {print COUNT " " CPU " " MEM}' | tail -1`;
	($pcount ,$cpu, $mem) = split(/\s+/, $val);
	if ($alert eq 'c') {
		$warn = "null";
		$crit = "$threshold,$above_or_below";
	} elsif ($alert eq 'w') {
		$warn = "$threshold,$above_or_below";
		$crit = "null";
	}
	# Processing process count against threshold
	$status = "";
	$rc = "";
	if ($alert eq 'c' && $above_or_below eq 'below') {
		if ($pcount < $threshold) {
			$status = "CRITICAL";
			$rc = "2";
		}
	} elsif ($alert eq 'c' && $above_or_below eq 'above') {
		if ($pcount > $threshold) {
			$status = "CRITICAL";
			$rc = "2";
		}
	} elsif ($alert eq 'w' && $above_or_below eq 'below') {
        	if ($pcount < $threshold) {
                	$status = "WARNING";
                	$rc = "1";
        	}
	} elsif ($alert eq 'w' && $above_or_below eq 'above') {
        	if ($pcount > $threshold) {
                	$status = "WARNING";
                	$rc = "1";
        	}
	} 
	if ($status eq "") {
		$status = "OK";
		$rc = "0";	
	}	
        $length += length($exit);
        if ($length >= 975) {
                $exit = "Exceeding 1024 characters limit";
                push(@print, "$exit\n");
        }
	$exit = "$rc\:\:Process Count $status\:\:$errcode\:\:warn=$warn,critical=$crit\:\:process=$process,count=$pcount,cpu=$cpu,mem=$mem\:\:count=$pcount, cpu=$cpu, mem=$mem";
	push(@print, "$exit\n");
}
print "@print";
