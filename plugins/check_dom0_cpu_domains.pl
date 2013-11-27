#!/usr/bin/perl 
#use strict;
$crit_found = '0';
$warn_found = '0';
my $XMTOP = 'sudo /usr/sbin/xentop';

sub print_usage {
print "check_dom0_cpu_domains.pl -e 'ErrorCode' -w 'Warning Threshold' -c 'Critical Threshold'
-h . This help. \n";
}

use Getopt::Long qw(:config no_ignore_case bundling);
$validate = GetOptions(
		'w=i'  => \$warn, 'warn=i' => \$warn,
		'c=i'  => \$crit, 'crit=i' => \$crit,
		'e=s'  => \$errc, 'errc=s' => \$errc,
		'h'    => \$help, 'help'   => \$help,
		);

if (!$validate ){
	&print_usage;
	exit 3;
}

if ($help){
	&print_usage;
	exit 3;
}

if (! defined $warn){
	$warn = 'null';
}

if (! defined $crit){
	$crit = 'null';
}

if (! defined $errc){
	$errc = 'null';
}

$ENV{PATH} = '/bin:/usr/bin:/usr/sbin';
my @chunks; undef(@chunks);
# run the xentop command a few times because the first reading is not always accurate
	local $/ = undef;
	@chunks = split(/^xentop - .*$/m, `$XMTOP -b -i 3 `);
if ($? != '0'){
print "Could not run $XMTOP Sucessfully. Check if sudo permissions exists for user nagios.\n";
exit 3;
}
# Take only the last run of xentop
my @stats = split (/\n/,pop(@chunks));

# remove the first 4 items that are junk that we don't need.
shift(@stats); 
shift(@stats); 
shift(@stats); 
shift(@stats); 

my %vals; undef(%vals);

foreach my $domain (@stats) {
# trim the leading whitespace
	$domain =~ s/^\s+//;
	my @v_tmp = split(/\s+/, $domain);

# we need to change - and . to _ . 
	$v_tmp[0] =~ s/[-.]/_/g;
	$vals{$v_tmp[0]}{'cpu_percent'} = $v_tmp[3];
	$vals{$v_tmp[0]}{'vcpu'} = $v_tmp[8];
	if ( $vals{"$v_tmp[0]"}{'vcpu'} =~ m/n\/a/ ) {
		my $cpu = `grep -c "processor" < /proc/cpuinfo`;
		if ( $cpu =~ m/^(\d+)$/ ) {
			$vals{$v_tmp[0]}{'vcpu'} = $1;
		}
	}
}

foreach my $key (sort(keys(%vals))) {
	$val = sprintf( "%d" , ($vals{$key}{'cpu_percent'}/$vals{'Domain_0'}{'vcpu'}));
        if ($val !~ /^\d+$/ ){
                print "Evaluvated output of 'sudo /usr/sbin/xentop' is not numeric . Please check sudo permissions for nagios.\n";
                exit 3;
        }

#print "$val \n";
	$result .=  "$key=$val ";
	if ( $crit ne 'null' ) {
		if ($val >= $crit ){
			$crit_found = '1' ;
		}
	}
	if ( $warn ne 'null' ) {
		if ($val >= $warn ){
			$warn_found = '1' ;
		}
	}
}
if ( $crit_found == '1'){
	print "Dom CPU usage CRITICAL ::${errc}:: warn=${warn},crit=${crit} :: $result | $result\n"; 
	exit 2;
}
if ( $warn_found == '1'){
	print "Dom CPU usage WARNING ::${errc}:: warn=${warn},crit=${crit} :: $result | $result\n"; 
	exit 1;
}
print "Dom CPU usage OK ::${errc}:: warn=${warn},crit=${crit} :: $result | $result\n";
exit 0;
