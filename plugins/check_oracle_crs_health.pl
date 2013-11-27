#!/usr/bin/perl

##########################################################################
# Name   : check_oracle_crs_health.pl
# Author : Mahesh Bhat
# Syntax : -c <crs_command> [-e <errocode>] [-h]
# Description : This plugin executes the given External crsctl Oracle Command
# Note : Run check_oracle_crs_health.pl -h for a detailed description
##########################################################################


use Getopt::Std;
getopts('e:c:ah');
my $errorcode = $opt_e;
my $cmdin = $opt_c;
my @error;
my $toutval = 8;
my @command = ();
my $cmdoutfile = '/usr/local/nagios/cmdhealthout.txt';
my $cmddef = '/opt/oracle/product/10gR2/crs/bin/crsctl';
#my $cmddef = '/opt/oracle/product/10gR2/crs/bin/crsctl check crs';
my $com;
my $exit;
my $timerstat;
my $psstat;
my $greppsstr =  'crsctl';
my $errstr='';
my $comusr = 'root';
my $pscom = "ps -ef | grep -i \"$greppsstr\" | grep -v grep | awk '{print \$1}'"; 

sub help {
    print <<EOT

    This plugin executes the given External crsctl Oracle Command

    Usage:

      \t$0 -c <crs_command> [-e <errocode>] [-h]

EOT
}
if ($opt_h) { help(); exit 3 };
if (!defined $cmdin) {
   $cmdin = $cmddef;
}
$com = "sudo -u root $cmdin check crs 2>$cmdoutfile";

$timerstat = &timer_check($pscom);
if ($timerstat == 2) {
   if (@command && ($exit == 0)) { #command executed fine
      chomp ($_) foreach @command;
      if (my $hungnum = grep (/$comusr/i,@command)) {  #Yes ! Those defunct processes are mine !
         print "CRS Error :: $errorcode :: alarm=crit :: CRS CHECK Command Hung,Defunct Processes=",$hungnum," | count=0\n";
         exit 2;
      }
   }
   elsif ($exit != 0) {
      $errstr = &errformat();
      print "BROKEN MONITOR - CRITICAL :: ESM00016 :: alarm=crit :: Zombie Check Stage Failed - $errstr\n";
      exit 2;
   }
} 
else {
    print "BROKEN MONITOR - CRITICAL :: ESM00016 :: alarm=crit :: Zombie Check Stage Failed - ps command Timed Out\n";
    exit 2;
}
@command = ();  #Clear the @command array
$timerstat = &timer_check($com);

if ($timerstat == 2) { #No TimeOut
   if ($exit != 0){
      $errstr = &errformat();
      print "BROKEN MONITOR - CRITICAL :: ESM00016 ::  alarm=crit :: $errstr\n";
      exit 2;
   }
   @final = grep(/healthy/,@command);
   $count = $#final + 1 ;
   if ($count < 3) {
      print "CRS Error :: $errorcode :: alarm=crit :: count=$count | count=$count\n";
      exit 2;
   }
   else {
      print "CRS Healthy :: $errorcode :: alarm=crit :: count=$count | count=$count\n";
      exit 0;
   }
}
else { #TimeOut !!
    print "CRS Error :: $errorcode :: alarm=crit :: CRS CHECK Script Timed Out | count=0\n";
    exit 0; #Dont raise alarm on timeout. Idea is to look for zombies first and then alert
}

sub errformat {
   
   if (@command) { #Supposed to contain the Error Condition. Since we run the command as root, it will not be in this variable !
      chomp($_);
      foreach (@command) {
        $errstr = $errstr.",$_";
      }
      $errstr = substr($errstr,1); #Chop off the extra first comma
   }
   elsif (-e $cmdoutfile) { #Read contents of the command output file only if the output file exists !
       if (open(OUTFILE,"<$cmdoutfile")) { 
          while (<OUTFILE>) {
             chomp($_);
	     $errstr = $errstr.",$_";
          }
          $errstr = substr($errstr,1); #Chop off the extra first comma
       }
       else {
            $errstr = 'Unknown Error';
       }
   }
   else {
      $errstr = 'Unknown Error';
   }
    return $errstr;
}


sub timer_check {
  my $com = shift;
  my $sw;

  eval {
     $SIG{'ALRM'} = sub { die "timeout" };
     alarm($toutval);
        @command = `$com`; 
     alarm(0);
  };
  $exit = $? >> 8; 
  if ($@ =~ /timeout/) {
     $sw=1;
  }
  else {
     alarm(0);  #Clear the still-pending alarm
     $sw=2;
  }
  return $sw;
}


