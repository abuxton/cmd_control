#!/usr/bin/perl

use strict;
use warnings;

my $file = $ARGV[0];
undef @ARGV;

die "$0 <filename>\n" if (!defined($file));

my $result = "No faults detected in $file";
if (-s $file )
{

  $result = "";
  open (IN, "<$file") or $result = "$!";

  while (<IN>)
  {
    $result = $result.$_;
  }
    close IN;
} elsif (-e $file)
{
  $result = "Scheduled Down" if ($file =~ /SERVER_DOWN$/);
} else {
  $result = "Scheduled Up" if ($file =~ /SERVER_DOWN$/);
}

my $check = "Check File";
$check = "Check Server Host" if ($file =~ /SERVER_DOWN/);
$check = "Check Server Services" if ($file =~ /SERVER_STATUS$/);

print $result;

