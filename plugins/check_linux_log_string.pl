#!/usr/bin/perl
#######################################################################################################
# Name        : check_log.pl 
# Version     : 2.1
# Date        : 12/09/2008
# Author      : Magin George
# Description :  checl_log.pl is the perl plugin that runs on the remotehost for monitoring
#		rotating and non rotating logfiles based on a rules file.
#		The syntax is ./check_log.pl -l /path/to/file -r /path/to/rulesfile -o servicename
#		This is script is called by the check_remotelog.pl from the monitoring server via
#		NRPE. The contents of the rules file should be formatted in the specifed format
#		like 
#	  	"ORA-10::UNX00009::2"
#		<string/regex-to-search>::<errorcode>::<sevirity-level>
#		servirity level is 1 for WARNING and 2 for CRITICAL 
#		This script also supports the date MACRO which can be used for monitoring
#		the rotating log files.
#		the standard date macros are 
#		
#		%hortyear 	==> YY   	==> 08
#		%year  	   	==> YYYY 	==> 2008
#		%ddmonth   	==> mm   	==> 09
#		%month     	==> m    	==> 12
#		%monthname 	==> Mmm  	==> Dec	
#		%fullmonthname 	==> Mmmmmmm 	==> December
#		%ddday 	       	==> dd      	==> 02
#		%day	       	==> d       	==> 19
#		%weekdayname   	==> Www     	==> Wed
#		%fullweekdayname==> Wwwwww 	==> Thursday
#		%ddhour  	==> hh 		==> 03
#		%hour		==> h 		==>11
#
#
##########################################################################################################
use Getopt::Std;
getopts('wcH:l:r:o:s:');
$name = "check_log.pl";
$host = ($opt_H);
$logfile = ($opt_l);
$string = ($opt_s);
$servname = ($opt_o);

if ((!defined $logfile)||(!defined $string)||(!defined $servname)){
	&print_usage;
}


$string =~ s/\%([0-9A-Fa-f]{2})/pack('C', hex($1))/ge;
#print "DEcoded string is $string\n";

unless (-e "$logfile"){
print "LOG-FILE \"$logfile\" does not exists.This may also happen if logfiles parent directory(ies) does not have -x permission for nagios \n";
exit 3;
}

unless (-r "$logfile"){
print "LOG-FILE \"$logfile\" is not readable by nagios.\n";
exit 3;
}


if (defined $opt_w){
$rc = 1 ;
}
if (defined $opt_c) {
$rc = 2 ;
}
sub print_usage {
	print 'Usage: check_log.pl -l <logfile> -s <string/regex> -o <servname> -<w|c>
	
Following are the date variables that you can use in the
log file name in case of rotating log files.
	
               %shortyear 	==> 	YY   	==> 08
               %year      	==> 	YYYY 	==> 2008
               %ddmonth   	==> 	mm   	==> 09
               %month     	==>	m    	==>  9
               %monthname 	==> 	Mmm  	==> Dec
               %fullmonthname 	==> 	Mmmmmmm ==> December
               %ddday         	==> 	dd      ==> 02
               %day           	==> 	d       ==>  2
               %weekdayname   	==> 	Www     ==> Wed
               %fullweekdayname	==> 	Wwwwww 	==> Thursday
               %ddhour  	==> 	hh	==> 03
               %hour   		==> 	h 	==>  1
';
	exit 2;
}

open (FILE,"$logfile") or die "cannot find $logfile file";


if (! -e "/usr/local/nagios/tmp/$servname") {
	chomp($first_time=`wc -l $logfile | awk '{print \$1;}'`);
	$write = system ("touch /usr/local/nagios/tmp/$servname; echo $first_time > /usr/local/nagios/tmp/$servname");
	&writeerror;
	&done;
}

LOOP:
chomp($numoflines = `wc -l $logfile|awk '{print \$1;}'`);
chomp($linesread = `cat /usr/local/nagios/tmp/$servname`);
&done if ($numoflines == $linesread);
$linestoberead = ($numoflines-$linesread);
if ($linestoberead < 0){
	$write = system ("echo 0 > /usr/local/nagios/tmp/$servname");
	&writeerror;
	goto LOOP;
}
$newlinesread = $linesread + 1 ;

@tail = `sed -n '$newlinesread , $numoflines p' $logfile`;
@array = "";
@matched = grep(/$string/i ,@tail);



$nummatched = scalar (@matched);
if ($nummatched > 0){
push (@numarray,"$rc\:\:$servname\:\:$host\:\:$errorcode\:\:The string/regex \"$string\" - matched $nummatched time(s)\n");
}	
foreach $match (@matched) {			
$error = "yes";
push (@array,"$rc\:\:$servname\:\:$host\:\:$errorcode\:\:$match");
}
		
	 	
		

$write = system ("echo $numoflines > /usr/local/nagios/tmp/$servname");
&writeerror;


use bytes;
  my $count = 0;

    foreach my $item (@array){
      $count += length($item); 
  }
	if ($count <= 1024 ){
	print @array ;	
	}else{
	print @numarray  ;
		}




if (!defined $error){
	&done;
}
sub done {
	print "LOG FILE $logfile OK-No matches\n";
	close FILE;
	close RULES;
	exit 0;
}
sub writeerror {
	if ($write != 0){
	print "Write error !! /usr/local/nagios/tmp/$servname is not writable \n";
	exit 0;
	} 	
}
