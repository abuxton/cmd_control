#!/usr/bin/perl
use strict;
my ($severity,$message,$line,@versions,$nrpe_plugin_version,$nrpe_binary_version,$os_version,$arch);
$nrpe_plugin_version = "Unknown";
$nrpe_binary_version = "Unknown";
$arch = `uname -i` or $arch = "Unknown" ;
chomp $arch ;
$os_version = `cat /etc/redhat-release`;
chomp $os_version ;
if ($os_version eq "") {
$os_version = "Unknown";
}
my $command = "rpm -qa |grep nrpe";
my $result = `$command`;
my $exit = $? >>8 ;
if ($exit != 0){ # command faild
($severity,$message) = ('2',"Running command rpm -qa [pipe] grep nrpe - failed or returned no output ");
&report_error($severity,$message);
}else{
my @versions = split("\n",$result);
        foreach $line (@versions){
        chomp $line;
                if ($line =~ /nrpe_2-12_ssl_rhel_plugins-01\.2-(\d+)/){
                $nrpe_plugin_version = 'nrpe_2-12_ssl_rhel_plugins-01.2-'.$1;
                }elsif ($line =~ /nrpe_2-12_ssl_rhel-01\.2-(\d+)/){
                $nrpe_binary_version = 'nrpe_2-12_ssl_rhel-01.2-'.$1;
                }
        }
print "NRPE Version Ok ::  :: Not running :: Arch = $arch , OS = $os_version , Plugin_ver=$nrpe_plugin_version , Binary_ver=$nrpe_binary_version \n";
}

sub report_error {
($severity,$message) = @_ ;
print "NRPE version check CRITICAL ::  :: :: $message \n";
exit $severity;
}

