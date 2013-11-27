#!/usr/bin/perl -w

use Getopt::Long;
   
use strict;

my $conncount;
my $o_help;
my $o_warn;
my $o_err;
my $o_crit;
my $o_port;
my @error;
my $validate;

my $DEFTIMEOUT = 9; #Default TimeOut Duration(Preferably <10). Decrease this value if messsage "NRPE:Socket timed out...." is seen at the slave

sub help {
    if (@_) {
       print "$_\n" foreach @error;
    }
    print <<EOT
    
    This plugin counts the total number of connections for a given port

    Usage: 

      \t$0 [-w <warning connections> | -c <critical connections>] [-e <errocode>] -p <port number> [-h]

EOT
}

$validate = GetOptions(
  		'p=i' => \$o_port,      'port=i' => \$o_port,
  		'w=i' => \$o_warn,      'warn=i' => \$o_warn,
  		'c=i' => \$o_crit,      'crit=i' => \$o_crit,
  		'e=s'  => \$o_err,      'errorcode=s'  => \$o_err,
  		'h'    => \$o_help,     'help'  => \$o_help
	   );

if ($o_help or !$validate) { help(); exit 3 };

#Mandatory fields

#If Errorcode is given, then at least one of the timeout warnings/alert specification must exist
if ((defined $o_err) and (!defined $o_warn) and (!defined $o_crit)) {
   unshift(@error,'The threshold values are missing');
}

#Critical Timeout threshold must be greater than Warning Timeout threshold
if ((defined $o_warn) and (defined $o_crit)) {
   if ($o_crit <= $o_warn) {
      unshift(@error,'Critical threshold must be greater than the Warning threshold');
   }
}

if (@error) {
   &help(1);
   exit 3;
}

chomp($conncount = &timer_check);

if ($conncount == -1) { #Netstat command was killed after DEFTIMEOUT seconds
   print 'Operation Timed Out - HIGH LOAD !::',(defined $o_err)?$o_err:'null','::warn=',(defined $o_warn)?$o_warn:'null',',critical=',(defined $o_crit)?$o_crit:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,',count=',$conncount;
   exit 2;
}
else { #Netstat command completed successfully within DEFTIMEOUT seconds
   if ((defined $o_crit) && ($conncount >= $o_crit)) {
      print 'Open Connection Count CRITICAL::',(defined $o_err)?$o_err:'null','::warn=',(defined $o_warn)?$o_warn:'null',',critical=',$o_crit,'::port=',$o_port,',count=',$conncount,'|port=',$o_port,',count=',$conncount;
      exit 2;
   }
   elsif ((defined $o_warn) && ($conncount >= $o_warn)) {
      print  'Open Connection Count WARNING::',(defined $o_err)?$o_err:'null','::warn=',$o_warn,',critical=',(defined $o_crit)?$o_crit:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,',count=',$conncount;
      exit 1;
   }
   else {
      print 'Open Connection Count OK::',(defined $o_err)?$o_err:'null','::warn=',(defined $o_warn)?$o_warn:'null',',critical=',(defined $o_crit)?$o_crit:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,',count=',$conncount;
      exit 0;
   }
}

sub timer_check {

 my $conn='';

 $SIG{ALRM} = sub { die "timeout" };
  eval {
     alarm($DEFTIMEOUT);
     $conn = `/bin/netstat -a --numeric-ports | grep -i ESTABLISHED | grep $o_port | wc -l`;
     alarm(0);
  };
  if ($conn eq '') {
     return -1;
  }
  else {
     alarm(0);  #Clear the still-pending alarm
     return $conn; 
  }
}
