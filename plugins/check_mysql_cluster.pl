#!/usr/bin/perl

use strict;

#################################################################################
#This plugin executes a command/script and searches for the given string in the output
# USAGE:
#  check_cmd_aim.pl -w|-c -e err_code -k command -o comma_separated_arguments_for_command -s errorstring,okstring
#################################################################################

use Getopt::Std;

my %opt;
my $arg;
my $err_code;
my $alarm;
my $cmd;
my $exit;
my $str;
my @okstr;
my $regok;
my $res;
my $thresh;
my $perf;
my $statusstr;
my $gdata;
my $exitcode;
my $retstr;

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
   ($str,@okstr) = split /,/,$opt{s};
} else {
   chomp($str="null");
}

if (! -f $opt{k}) {
   $statusstr = 'Command Failed';
   $res = sprintf("File %s does not exist",$opt{k});
   $cmd = $opt{k};
   $gdata = ($alarm eq "crit" or $alarm eq "null")?'Status=2':'Status=1';
   if ($alarm eq 'null') {
      $exitcode = 0;
   }
   else  {
      $exitcode = ($alarm eq 'crit')?2:1;
   }
}
elsif (! -x $opt{k}) {
      $statusstr = 'Command Failed';
      $res = sprintf("File %s is not Executable",$opt{k});
      $cmd = $opt{k};
      $gdata = ($alarm eq "crit" or $alarm eq "null")?'Status=2':'Status=1';
      if ($alarm eq 'null') {
         $exitcode = 0;
      }
      else  {
         $exitcode = ($alarm eq 'crit')?2:1;
      }
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
   chomp($res = qx($cmd 2>&1));
   $exit = $? >> 8;
   if ($exit != 0){
      print "Cant run the command : $cmd \n";
      &print_usage;
      exit 3;
   }
   if (grep(/\n/,($res))) { #To use chomp, initialize $\="\n". I dont like the idea
      $res =~ s/\n//g;
   }
   $res =~ s/^\s*(\S*(?:\s+\S+)*)\s*$/$1/; #Trim Preceding or Trailing White Spaces, if any

   foreach (@okstr) { #Frame the Regular Expression in case there is  multiple good strings
      $regok .= "(^$_\$)|" 
   } 
   chop($regok);


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
      elsif ($alarm eq "null" && $res =~ /$str/i) {
         $statusstr = 'Content Match in ERROR';
         $gdata = 'Status=2';
         $exitcode = 0;
      }
      elsif (defined @okstr && $res =~ /$regok/i) { #Look for a whole match of the Okstr
         $statusstr = 'Content Matched OK';
         $gdata = 'Status=0';
         $exitcode = 0;
      } 
      else {
         $statusstr = 'Unknown String Found';
         my $tmpres = $res;
         $res = (defined $str)?sprintf("Permitted Output-'%s',Command Output-'%s'",$opt{s},$tmpres):sprintf("Permitted Output-'%s',Command Output-'%s'",$str,$tmpres); 
         $gdata = ($alarm eq "crit" or $alarm eq "null")?'Status=2':'Status=1';
         if ($alarm eq 'null') {
            $exitcode = 0;
         }
         else  {
            $exitcode = ($alarm eq 'crit')?2:1;
         }
      }
   } 
   elsif (! defined $opt{s}) { #No Apparent use of this branch !
      $statusstr = 'Command Succeeded';
      $gdata = 'Status=0';
      $exitcode = 0;
   }
}

$thresh = sprintf("alarm=%s",$alarm); 
$perf = (defined $str)?sprintf("result=%s,content_match=%s,script=%s",$res,$opt{s},$cmd):sprintf("result=%s,content_match=%s,script=%s",$res,$str,$cmd);

$retstr = join('|',join('::',$statusstr,$err_code,$thresh,$perf),$gdata);

print $retstr;
exit $exitcode;

sub print_usage {
        print <<EOT
	This plugin executes a command/script and searches for the given string in the output
	USAGE: 
             check_cmd_aim.pl -w|-c -e err_code -k command -o comma_separated_arguments_for_command -s errorstring,okstring1,okstring2,.....	          ..okstringn
EOT
}
