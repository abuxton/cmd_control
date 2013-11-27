#! /usr/bin/perl -w

use strict;
use FindBin;
use lib $FindBin::Bin;
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME $PROGVER);
use Getopt::Long;
use vars qw($opt_V $opt_proc $opt_warn $opt_crit $verbose $opt_h);

$PROGNAME = "check_long_running_proc";
$PROGVER = "1.0";

sub print_help();
sub print_usage();

Getopt::Long::Configure('bundling');
GetOptions ("V" => \$opt_V, "version" => \$opt_V,
        "p=s" => \$opt_proc, "proc" => \$opt_proc,
        "w=i" => \$opt_warn, "warning" => \$opt_warn,
        "c=i" => \$opt_crit, "critical" => \$opt_crit,
        "h" => \$opt_h, "help" => \$opt_h);

if ($opt_V) {
    print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
    exit $ERRORS{'UNKNOWN'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'UNKNOWN'};
}

print_usage() unless ($opt_proc);

# ps will sort results by process length, descending
my $etime = `/bin/ps -eo "%t %a" | /bin/grep "$opt_proc" | /bin/awk '{print \$1}' | /usr/bin/head -1`;
chomp $etime;

my $days = 0;
my $hours = 0;
my $minutes = 0;

if($etime =~ /^(\d+)-/) {
    $days = $1;
}
if($etime =~ /(\d+):(\d+):\d+$/) {
    $hours = $1;
    $minutes = $2;
} 
elsif($etime =~ /(\d+):\d+$/) {
    $minutes = $1;
}

my $t = ($days * 1440) + ($hours * 60) + $minutes;

if($opt_crit && $t >= $opt_crit)
{
    print "CRITICAL: Process has been running for $t minutes.";
    exit $ERRORS{'CRITICAL'};
}

if($opt_warn && $t >= $opt_warn)
{
    print "WARNING: Process has been running for $t minutes.";
    exit $ERRORS{'WARNING'};
}

print "OK: Process running for $t minutes.";
exit $ERRORS{'OK'};

sub print_usage () {
    print "Usage: $PROGNAME -p <proc> [-w <age>] [-c <age>] [-V] [-h]\n";
    exit $ERRORS{'UNKNOWN'} unless ($opt_h);
}

sub print_help () {
    print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
    print "Copyright (c) 2008 Electronic Arts\n";
    print "\n";
    print_usage();
    print "\n";
    print "-p <proc> = Process name\n";
    print "-w <age> = Warning age threshold, in minutes\n";
    print "-c <age> = Critical age threshold, in minutes\n";
    print "-V = Get version.\n";
    print "-h = This screen\n\n";
    support();
}

