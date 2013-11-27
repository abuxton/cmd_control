#!/usr/bin/perl

##########################################################################
# Name   : check_oracle_crs_offline.pl
# Author : Mahesh Bhat
# Syntax : -c <crs_command> [-e <errocode>] [-h]
# Description : This plugin executes the given External crs_stat Oracle Command
# Note : Run check_oracle_crs_offline.pl -h for a detailed description
##########################################################################

use Getopt::Std;
getopts('e:c:ah');
my $errorcode = $opt_e;
my $cmdin = $opt_c;
my $toutval = 8;
my @command = ();
my $cmdoutfile = '/usr/local/nagios/cmdofflineout.txt';
my $cmddef = '/opt/oracle/product/10gR2/crs/bin/crs_stat ';
#my $cmddef = '/opt/oracle/product/10gR2/crs/bin/crs_stat -t';
my $com;
my $exit;
my $timerstat;
my $psstat;
my $greppsstr =  'crs_stat';
my $errstr='';
my $comusr = 'root';
my $pscom = "ps -ef | grep -i \"$greppsstr\" | grep -v grep | awk '{print \$1}'";

sub help {
    print <<EOT

    This plugin executes the given External crs_stat Oracle Command

    Usage:

      \t$0 -c <crs_command> [-e <errocode>] [-h]

EOT
}
if ($opt_h) { help(); exit 3 };
if (!defined $cmdin) {
   $cmdin = $cmddef;
}
if (!defined $opt_e){
   $opt_e = "null";
}
$com = "sudo -u root $cmdin -t 2>$cmdoutfile";

$timerstat = &timer_check($pscom);
if ($timerstat == 2) {
   if (@command && ($exit == 0)) { #command executed fine
      chomp ($_) foreach @command;
      if (my $hungnum = grep (/$comusr/i,@command)) {  #Yes ! Those defunct processes are mine !
         print "CRS Error :: $errorcode :: alarm=crit :: CRS_STAT CHECK Command Hung,Defunct Processes=",$hungnum," | count=0\n";
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
   @final = grep(/offline/i,@command);
   $count = $#final + 1 ;
   if (@final != 0) {
      print "CRS OFFLINE - CRITICAL:: $opt_e :: alarm=crit :: Count=$count |Count=$count\n";
      exit 2;
   }
   else {
      print "CRS OK - OK:: $opt_e :: alarm=crit :: Count=$count |Count=$count\n";
      exit 0;
   }
}
else { #TimeOut !!
    print "CRS OFFLINE - CRITICAL:: $opt_e :: alarm=crit :: CRS_STAT Script Timed Out | count=0\n";
    exit 0; #Dont raise alarm on timeout. Idea is to look for zombies first and then alert
}

sub errformat {

   if (@command) { #contains the Error Condition
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


