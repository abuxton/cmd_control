#!/usr/bin/perl
use strict;
my $name = 'check_generic_script_output.pl';
my ($host,$warn,$crit,$errc,$script,$result,%sev,$ok,$oko,$warning,$critical,$exit,$severity,$help,$perfdata,$output) ;
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
$result =~ s/^\s*//g;
$result =~ s/\s*$//g;
$exit = $? >>8;

my @warning_elements = split (',',$warn);
my @critical_elements = split (',',$crit);
my @ok_elements = split (',',$oko);
if (grep /^$result$/, @critical_elements){
&print_result($critical,$result);
}elsif (grep /^$result$/, @warning_elements){
&print_result($warning,$result);
}elsif (grep /^$result$/, @ok_elements){
&print_result($ok,$result);
}else{
&print_result_error($critical,$result);
}

sub print_result {
($severity,$result) = @_ ;
print "Script output $result found in $sev{$severity} ::${errc}:: -w $warn -c $crit -o $oko :: Script output $result found in $sev{$severity}. \n";
exit $severity ;
}

sub print_result_error {
($severity,$result) = @_ ;
print "Script output $result is NOT found in expected output list - $sev{$severity} ::${errc}:: -w $warn -c $crit -o $oko :: Script output $result is NOT found in expected output list - $sev{$severity}.\n";
exit $severity ;
}

sub print_help {
        print <<EOF;
Usage : $name -s <path and name of script> -w <warning script outputs seperated by ','> -c <critical script outputs seperated by ','> -o <ok script outputs seperated by ','> -e <errorcode>
                -s : absolute path to the script
                -w : warning script outputs seperated by ',' like -w WARN,WARNING .
                -c : critical script outputs seperated by ',' like -c ERROR,CRITICAL .
                -o : ok script outputs seperated by ',' like -o OK,CLEAR .
		-e : errorcode
                -h " This help.
EOF
                exit 3;
}

sub print_script_error {
        print "$result\n";
        exit $severity;
}

