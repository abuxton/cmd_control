#!/usr/bin/perl

use SNMP::Persist qw(&define_oid &start_persister &define_subtree);
use strict;
use warnings;

#define base oid to host the subtree
define_oid(".1.3.6.1.4.1.2023.248");

#start the thread serving answers
start_persister();

#loop forever to update the values
my $mpstatCmd = 'mpstat -P ALL 5';
open(MPSTAT_CMD, "$mpstatCmd |") or die "Can't run '$mpstatCmd'\n$!\n";

my %subtree;
my @value;
my $cpuUsage=0;
my $cpuUsageMax=0;
my $cpuId=0;
my $cpuIdLast=0;

while(<MPSTAT_CMD>) {
next if /(Linux|CPU|Average|all|^$)/;

@value = split(/\s+/);
$cpuId=$value[1];
$cpuUsage=$value[2]+$value[3]+$value[4]+$value[5]+$value[6]+$value[7]+$value[8];

if ( $cpuId <= $cpuIdLast ) {
  $subtree{"1." . 1}=["INTEGER",$cpuUsageMax];
  $subtree{"2." . 1}=["String","cpuTotal"];
  #new values have arrived - notify the subtree controller
  define_subtree(\%subtree);
}

if ( $cpuUsage > $cpuUsageMax || $cpuId <= $cpuIdLast ) {
  $cpuUsageMax=$cpuUsage;
}

$cpuIdLast=$cpuId;

}

