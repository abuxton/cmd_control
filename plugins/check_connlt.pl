#!/usr/bin/perl -w

use Getopt::Long;
   
use strict;

my $conncount;
my $o_help;
my $o_alert;
my $o_err;
my $o_port;
my @error;
my $validate;

my $DEFTIMEOUT = 20; #Default TimeOut Duration(Preferably <10)

sub help {
    if (@_) {
       print "$_\n" foreach @error;
    }
    print <<EOT
    
    This plugin counts the total number of connections for a given port

    Usage: 
 
      \t$0 [-a w|c] [-e <errocode>] -p <port number> [-h]

EOT
}

$validate = GetOptions(
  		'p=i' => \$o_port,      'port=i' => \$o_port,
  		'a=s' => \$o_alert,      'alert=s' => \$o_alert,
  		'e=s'  => \$o_err,      'errorcode=s'  => \$o_err,
  		'h'    => \$o_help,     'help'  => \$o_help
	   );

if ($o_help or !$validate) { help(); exit 3 };

chomp($conncount = &timer_check);

if ($conncount == -1) { #Netstat command was killed after DEFTIMEOUT seconds
   print 'Operation Timed Out - HIGH LOAD !::',(defined $o_err)?$o_err:'null','::alarm=',(defined $o_alert)?$o_alert:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,', count=',$conncount;
   exit 2;
}
else { #Netstat command completed successfully within DEFTIMEOUT seconds
   if ((defined $o_alert) && ($o_alert =~ /w/i) && ($conncount == 0)) { #Alerting Severity is set to warning
      print 'Established Connection Count WARNING::',(defined $o_err)?$o_err:'null','::alarm=',(defined $o_alert)?$o_alert:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,', count=',$conncount;
      exit 1;
   }
   elsif ((defined $o_alert) && ($o_alert =~ /c/i) && ($conncount == 0)) { #Alerting Severity is set to critical
      print 'Established Connection Count CRITICAL::',(defined $o_err)?$o_err:'null','::alarm=',(defined $o_alert)?$o_alert:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,', count=',$conncount;
      exit 2;
   }
   elsif ($conncount == 0) { #If Alerting Severity not set then treat it as critical
      print 'Established Connection Count CRITICAL::',(defined $o_err)?$o_err:'null','::alarm=',(defined $o_alert)?$o_alert:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,', count=',$conncount;
      exit 2;
   }
   else { #All Well
      print 'Established Connection Count OK::',(defined $o_err)?$o_err:'null','::alarm=',(defined $o_alert)?$o_alert:'null','::port=',$o_port,',count=',$conncount,'|port=',$o_port,', count=',$conncount;
      exit 0;
   }
}

sub timer_check {

 my $conn='';

 $SIG{ALRM} = sub { die "timeout" };
  eval {
     alarm($DEFTIMEOUT);
     $conn = `/bin/netstat -ne -a --numeric-ports | grep -i ESTABLISHED | grep $o_port | wc -l`;
     alarm(0);
  };
  if ($conn eq '') {
     return -1;
  }
  else {
     alarm(0);  #Clear the still-pending alarm
     $conn =~ s/^\s+//;
     $conn =~ s/\s+$//;
     return $conn; 
  }
}
