#!/usr/bin/perl

use strict;

#################################################################################
#This plugin executes a command/script and searches for the given string in the output
# USAGE:
#  check_cmd_aim.pl -w|-c -e err_code -k command -o comma_separated_arguments_for_command -s errorstring,okstring
#################################################################################

use Getopt::Std;

use constant DEFTIMEOUT => 8;
my %opt;
my $arg;
my $err_code;
my $alarm;
my $cmd;
my $exit;
my $str;
my $okstr;
my $res;
my $thresh;
my $perf;
my $statusstr;
my $gdata;
my $exitcode;
my $retstr;
my $timeret;

getopts("wce:k:o:s:h", \%opt);

# Validate getopts output ?

if (defined $opt{h}) {
   &print_usage;
   exit 3; 
}

if (!defined $opt{k}) {
   print "Enter a valid Command with -k argument\n";
   &print_usage;
   exit 3;
}

if (defined $opt{e}) {
   chomp($err_code=$opt{e});
} else {
   chomp($err_code="null");
}

if (defined $opt{c}) {
   chomp($alarm="crit");
} elsif (defined $opt{w}){
   chomp($alarm="warn");
} else {
   chomp($alarm="null");
}

if (defined $opt{s}) {
   chomp($opt{s});
   ($str,$okstr) = split /,/,$opt{s};
} else {
   chomp($str="null");
}

if (! -f $opt{k}) {
   $statusstr = 'Command Failed';
   $res = sprintf("File %s does not exist",$opt{k});
   $gdata = ($alarm eq "crit" or $alarm eq "null")?'Status=2':'Status=1';
   $exitcode = ($alarm eq "crit" or $alarm eq "null")?2:1;
}
elsif (! -x $opt{k}) {
      $statusstr = 'Command Failed';
      $res = sprintf("File %s is not Executable",$opt{k});
      $gdata = ($alarm eq "crit" or $alarm eq "null")?'Status=2':'Status=1';
      $exitcode = ($alarm eq "crit" or $alarm eq "null")?2:1;
} 
else { #Script Exists and is Executable
   if (defined $opt{o}) {
      foreach (split /,/, $opt{o}) {;
         $arg .= ' '.$_; 
      }
      $cmd = $opt{k}." $arg";
   }
   else { #Extra arguments do not exist
      $cmd = $opt{k};
   }
   # Call to Timer Function 
   $timeret = &timer_check($cmd);
   if ($exit != 0){  #Test if this value persists out here
      print "Cant run the command : $cmd \n";
      &print_usage;
      exit 3;
   }
   if ($timeret == 2) { #NO TIMEOUT !
      if (grep(/\n/,($res))) { #To use chomp, initialize $\="\n". I dont like the idea
         $res =~ s/\n//g;
      }
      if (defined $opt{s}) { #Match String Specified
         if ($alarm eq "crit" && $res =~ /$str/i) {
            $statusstr = 'Content Matched CRITICAL'; 
            $gdata = 'Status=2';
            $exitcode = 2;
         } 
         elsif ($alarm eq "warn" && $res =~ /$str/i) {
            $statusstr = 'Content Matched WARNING';
            $gdata = 'Status=1';
            $exitcode = 1;
         } 
         elsif (defined $okstr && $res =~ /^$okstr$/i) { #Look for a whole match of the Okstr
            $statusstr = 'Content Matched OK';
            $gdata = 'Status=0';
            $exitcode = 0;
         } 
         else {
            $statusstr = 'Unknown String Found';
            my $tmpres = $res;
            $res = (defined $str and defined $okstr)?sprintf("Permitted Output-'%s'/'%s',Command Output-'%s'",$str,$okstr,$tmpres):sprintf("Permitted Output-'%s',Command Output-'%s'",$str,$tmpres); 
            $gdata = ($alarm eq "crit" or $alarm eq "null")?'Status=2':'Status=1';
            $exitcode = ($alarm eq "crit" or $alarm eq "null")?2:1;
         }
      } 
      elsif (! defined $opt{s}) { #No Apparent use of this branch !
         $statusstr = 'Command Succeeded';
         $gdata = 'Status=0';
         $exitcode = 0;
      }
  } #End of NO-TIMEOUT-IF
  elsif ($timeret == 1) { #TIMEOUT !
     $res = 'DB SCRIPT TIMED OUT';
     if ($alarm eq "crit") { #Critical Severity
        $statusstr = 'MySQL Script Time Out-CRITICAL-INVESTIGATE';
        $gdata = 'Status=2'; 
        $exitcode = 2;
     }
     elsif ($alarm eq "warn") { #Warning Severity
        $statusstr = 'MySQL Script Time Out-WARNING-INVESTIGATE';
        $gdata = 'Status=1'; 
        $exitcode = 1;
     }
     else { #No Alarming Severity
        $statusstr = 'MySQL Script Time Out-INVESTIGATE';
        $gdata = 'Status=2'; 
        $exitcode = 0;
     }
  } #End of TIMEOUT-IF
}

$thresh = sprintf("alarm=%s",$alarm); 
$perf = (defined $okstr)?sprintf("result=%s,content_match=%s,%s,script=%s",$res,$str,$okstr,$cmd):sprintf("result=%s,content_match=%s,script=%s",$res,$str,$cmd);

$retstr = join('|',join('::',$statusstr,$err_code,$thresh,$perf),$gdata);

print $retstr;
exit $exitcode;

sub print_usage {
        print <<EOT
	This plugin executes a command/script and searches for the given string in the output
	USAGE: 
             check_cmd_aim.pl -w|-c -e err_code -k command -o comma_separated_arguments_for_command -s errorstring,okstring
EOT
}

sub timer_check {
  my $command = shift;
  my $sw;

  eval {
     $SIG{'ALRM'} = sub { die "timeout" };
     alarm(DEFTIMEOUT);
        $res = qx($command 2>&1);      
     alarm(0);
     $exit = $? >> 8; #Test if it evaluates to correct value and if this value persists out of this function
  };
  if ($@ =~ /timeout/) {
     $sw=1;
  }
  else {
     alarm(0);  #Clear the still-pending alarm
     $sw=2;
  }
  return $sw;
}
