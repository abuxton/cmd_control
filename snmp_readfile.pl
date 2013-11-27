#!/usr/bin/perl

use SNMP::Persist qw(&define_oid &start_persister &define_subtree);
use strict;
use warnings;
use Data::Dumper;

my $oid = $ARGV[0];
my $file = $ARGV[1];
undef @ARGV;


#define base oid to host the subtree
define_oid($oid);

#start the thread serving answers
start_persister();

#loop forever to update the values
# Open file ....
my $result;
while (1)
{

if (!defined($file))
{
$result = "File does not exist";
} else {
if (-s $file )
{

  $result = "";
  open (IN, "<$file") or $result = "$!";

  while (<IN>)
  {
    chomp $_;
    $result = $result.$_;
  }
  close IN;
}
}


  my %subtree;

  $subtree{"1." . 1}=["INTEGER",$result] if ($result =~ /^\d+$/);
  $subtree{"1." . 1}=["STRING",$result] if ($result !~ /^\d+$/);
  $subtree{"2." . 1}=["STRING","Average Queue Time"];
  #new values have arrived - notify the subtree controller
  define_subtree(\%subtree);

sleep 60;

}
