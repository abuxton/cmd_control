#!/usr/bin/perl
use strict ;

my $com = ' df -h |awk \'{if (NR!=1) {print}}\'| awk \'NF >= 3\' | awk  \'{print $NF}\'|awk \'NR==1{x=$0;next}NF{x=x" :: "$0}END{print x}\'';
my $result = `$com`;
my $exit = $?>>8;
unless ($exit){
	print "Partitions are $result ";
	exit 0;
}else{
	print "Command execution failed !! \n";
	exit 2;
}

