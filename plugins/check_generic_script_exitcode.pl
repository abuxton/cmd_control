#!/usr/bin/perl
use strict;
my $name = 'check_generic_script_exitcode.pl';
our ($host,$warn,$crit,$errc,$script,$result,%sev,$ok,$oko,$warning,$critical,$exit,$severity,$perf,$help,$output,$perfdata) ;
use Getopt::Long ;
my $validate =  GetOptions ('w=s' => \$warn,
		'c=s' => \$crit,
		'o=s' => \$oko,
		'e=s' => \$errc,
		's=s' => \$script,
		'h' => \$help
		);
($ok,$warning,$critical) = ('0','1','2');
my %sev = ( 
		0 => 'OK',
		1 => 'WARNING',
		2 => 'CRITICAL'
	  ); 


if ((!defined $script) || ( $validate == "") ||(defined $help)){
	&print_help;
}

if (! -e $script){
	$result = "Script $script does not exist";
	&print_script_error($critical,$result);
}

if  (! -x $script){
	$result = "Script $script is not executable by nagios";
	&print_script_error($critical,$result);
}

$result = `$script`;
chomp $result;
if ($result eq ""){ 
	$output = "null" ;
}else{
	if ($result =~ /^(.*?)\|(.*)$/){
		($output,$perf) = ($1,$2);
		 $perfdata = '|'."$perf";
	}else{
	$output = $result;
	}
}

$exit = $? >>8;

my @warning_elements = split (',',$warn);
my @critical_elements = split (',',$crit);
my @ok_elements = split (',',$oko);
if (grep /^$exit$/, @critical_elements){
	&print_result($critical,$result);
}elsif (grep /^$exit$/, @warning_elements){
	&print_result($warning,$result);
}elsif (grep /^$exit$/, @ok_elements){
	&print_result($ok,$result);
}else{
	&print_unexpeted_exitcode_error($critical,$result);
}

sub print_result {
	($severity,$result) = @_ ;
	print "Script output - $output -- $sev{$severity} :: $errc :: Script exit code -w $warn -c $crit -o $oko  :: $output - Script $script exited with exitcode of $exit. $perfdata\n";
	exit $severity ;
}

sub print_script_error {
	print "$result\n";
	exit $severity;
}
sub print_unexpeted_exitcode_error {
	($severity,$result) = @_ ;
	print "Script output - $output -- script exited with unexpected exitcode $exit :: $errc :: Script exit code -w $warn -c $crit -o $oko  :: Script output - $output -- script exited with unexpected exitcode $exit. $perfdata\n";
	exit $severity ;
}
sub print_help {
	print <<EOF;
Usage : $name -s <path and name of script> -w <warning exit codes seperated by ','> -c <critical exit codes seperated by ','> -o <ok exit codes seperated by ','> -e <errorcode>
		-s : absolute path to the script
		-w : warning exit codes seperated by ',' like -w 2,3,4 .
		-c : critical exit codes seperated by ',' like -c 12,13,14 .
		-o : ok exit codes seperated by ',' like -o 22,23,24 .
		-e : errorcode
		-h " This help.
EOF
		exit 3;
}


