#!/usr/bin/perl
#
# Constantly monitors the alert logs
# Called by nagios.
#
use File::Compare;
use File::Copy;


$file1 = "/home/cdc-ops/games/alert-plasma01/bug.txt";
$file2 = "/home/cdc-ops/games/alert-plasma01/bug.old";

#If the immediate.txt doesn't exist no need to proceed
if(!-e $file1)
{
        print "OK: No new Alerts\n";
        exit 0;
}


#Get a Line count of the two files then compair to see if new alerts are present
$lines1 = `wc -l $file1 | cut -d" " -f1`;
$lines2 = `wc -l $file2 | cut -d" " -f1`;

$lines = int($lines1) - int($lines2);

#No reason to proceed if the line count is < 1
if($lines > 0)
{
	#If the files are different we need to do alert
	if (compare($file1, $file2)) 
	{
		#Make a copy of the new file and copy it to the reference copy
        	copy($file1,$file2);

		if ($lines < 3)	{
			print "WARNING: $lines new lines in the alerts\n";
			exit 1;
		}
		else {
        		print "CRITICAL: $lines new lines in the alerts\n";
        		exit 2;
		}	
	}
}	
else
{
        print "OK: $lines new lines in the alerts\n";
        exit 0;
}

