#! /usr/bin/perl -w

use strict;
use FindBin;
use lib $FindBin::Bin;
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME $PROGVER);
use Getopt::Long;
use vars qw($opt_V $opt_path $opt_warn $opt_crit $verbose $opt_h);

$PROGNAME = "check_archive";
$PROGVER = "1.0";

sub print_help();
sub print_usage();

Getopt::Long::Configure('bundling');
GetOptions ("V" => \$opt_V, "version" => \$opt_V,
        "p=s" => \$opt_path, "path" => \$opt_path,
        "h" => \$opt_h, "help" => \$opt_h);

if ($opt_V) {
    print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
    exit $ERRORS{'UNKNOWN'};
}

if ($opt_h) {
    print_help();
    exit $ERRORS{'UNKNOWN'};
}

print_usage() unless ($opt_path);

# Hard-coded list of active telemetry archive folders
my @teleFolders = ("tele1","tele2","tele3","tele4","tele5","tele6","tele7","tele8","tele9","tele10","tele11","tele12","tele13","tele14");

my $curtime = `/bin/date '+%b %d %H:%M'`;
my ($month, $day, $hour, $minute) = $curtime =~ /^(\w+) (\d+) (\d+):(\d+)$/;

foreach my $teleX (@teleFolders)
{
    my $mtime = `/bin/ls -l $opt_path/. | /bin/grep $teleX | /usr/bin/head -1 | /bin/awk '{print \$6 " " \$7 " " \$8}'`;
    chomp $mtime;

    my ($m_month, $m_day, $m_hour, $m_minute) = $mtime =~ /^(\w+) (\d+) (\d+):(\d+)$/;

    if($month ne $m_month || $m_day != $day) {
        print "CRITICAL: Archive $teleX has not been updated since $m_month $m_day $m_hour:$m_minute.";
        exit $ERRORS{'CRITICAL'};
    }
}

print "OK: All archives updated $month $day";
exit $ERRORS{'OK'};

sub print_usage () {
    print "Usage: $PROGNAME -p <path> [-V] [-h]\n";
    exit $ERRORS{'UNKNOWN'} unless ($opt_h);
}

sub print_help () {
    print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
    print "Copyright (c) 2008 Electronic Arts\n";
    print "\n";
    print_usage();
    print "\n";
    print "-p <path> = Archive root\n";
    print "-V = Get version.\n";
    print "-h = This screen\n\n";
    support();
}

