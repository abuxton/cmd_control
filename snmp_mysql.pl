#!/usr/bin/perl

use SNMP::Persist qw(&define_oid &start_persister &define_subtree);
use strict;
use warnings;
use DBI;
use Sys::Hostname;

# This flag tells the script to assume the hostname is `hostname` if set to 0
# If set to 1, it reads the value from /var/spool/playfish/meta-data/playfish-name
my $valid_system_hostname = 0;

#define base oid to host the subtree
define_oid(".1.3.6.1.4.1.2021.248");

#start the thread serving answers
start_persister();

# ALWAYS add new SQL statements to the end.
# Adding anywhere else will change the OID which will mean an Icinga config change.
my @sql_statements = ( 'show status where Variable_Name = "Threads_connected"',
                       'show status where Variable_Name = "Created_tmp_disk_tables"',
                       'show status where Variable_Name = "Handler_read_first"',
                       'show status where Variable_Name ="Innodb_buffer_pool_wait_free"',
                       'show status where Variable_Name ="Key_reads"',
                       'show status where Variable_Name ="Max_used_connections"',
                       'show status where Variable_Name ="Open_tables"',
                       'show status where Variable_Name ="Select_full_join"',
                       'show status where Variable_Name ="Slow_queries"',
                       'show slave status',
                       'show status where Variable_Name = "Threads_running"',
                     );


#loop forever to update the values
my $dbh = _connectDB();

my @MYSQL_VER = _runSQL($dbh, "show variables like 'version'", 1, "Value");

while(1) {

  # Connect to mysql
  my %subtree;
  my $index=1;                                          #set first application number

  foreach my $sql_statement (@sql_statements) {
    my @value;
    if ($sql_statement =~ /show slave status/)
    {
      # If its 5.0.x
      if ( $MYSQL_VER[0] =~ /^5.0./)
      {
#warn "Running on 5.0.x";
        @value = _runSQL($dbh, $sql_statement, "32", "Sec_behind_master");
      } else {
#warn "Running on 5.5.x";
        @value = _runSQL($dbh, $sql_statement, "32", "Seconds_Behind_Master");
      }
      

      # If the slave is lagging, see if there are any other processes running
      if ( $value[1] > 0 )
      {
        my $running_processes = _getProcesslist($dbh, "show processlist");
        $value[1] = 0 if ($running_processes > 0);
#        print "There are $running_processes which do not look like system processes\n";
      }
    } else {
      @value = _runSQL($dbh, $sql_statement, "1");
    }
#print ">$value[0]<  >$value[1]<\n";
    $subtree{"1." . $index}=["INTEGER",$value[1]];
    $subtree{"2." . $index}=["STRING",$value[0]];
    $index++;                                                #next application
  }

  # Artifically inflate $index to be 100, to ensure maatkit test doesn't move
  $index=100;

  # Obtain the replication status from Maatkit (mk-heartbeat)
  my $hostRef = getMKResults();
  foreach my $key (keys(%$hostRef))
  {
    $subtree{"1." . $index} = ["INTEGER", $hostRef->{$key}];
    $subtree{"2." . $index} = ["STRING", "MAATKIT: $key" ];
    $index++;                                                #next application
  }

  #new values have arrived - notify the subtree controller
  define_subtree(\%subtree);

  #don't update for next 5 minutes
  sleep(300);
}

sub _getProcesslist
{
  my ($dbh, $sql) = @_;

  my $nonSystemProcess = 0;

  my $hostname = getHostname();
  if ($hostname =~ /\d\ds$/)
  {
    my $sth = $dbh->prepare($sql);
    $sth->execute
      or die "SQL Error: $DBI::errstr\n";

    while (my @row = $sth->fetchrow_array)
    {
      $nonSystemProcess++ if (( $row[1] !~ /^system user$/i) && ($row[1] !~ /^root$/i));
    }
  }

  return $nonSystemProcess;
}



sub _runSQL
{
  my ($dbh, $sql, $count, $variable) = @_;

  # Artificially sleep for 1 sec
  sleep 1;
  my $sth = $dbh->prepare($sql);
  $sth->execute
    or die "SQL Error: $DBI::errstr\n";
  my @row = $sth->fetchrow_array;

  my $value = 0;

  # If count is greater than 2, then we're trying to parse a multiline output
  $value = 99999 if (scalar(@row) > 2);
#  warn "count: ".scalar(@row). "  >$value<";

  $variable = "$variable (Not Configured)" if ((defined($variable)) && (scalar(@row) == 0));

#warn "$sql : >>$row[$count]<<";

  $value = $row[$count] if (defined($row[$count]));
  return ($variable, $value) if (defined($variable));
  return ($row[0], $value);
}


sub _connectDB
{
  my $dbh = DBI->connect('dbi:mysql:mysql;mysql_connect_timeout=30','root','')
 or die "Connection Error: $DBI::errstr\n";
  return $dbh;
}

sub getHostname
{

  my ($override) = @_;

  my $override_check = $valid_system_hostname;
  $override_check = 0 if (!defined($override));
  my $hostname;

  if ($override_check)
  {
    $hostname = hostname;
  } else {
    open (IN, "< /var/spool/playfish/meta-data/playfish-name");
    $hostname = (<IN>);
    chomp $hostname;
    close IN;
    $hostname = hostname if ($hostname eq "");
  }

  return $hostname;
}

sub convertSystemHostnameToPlayfishName
{
  my ($hostname) = @_;
  if ($hostname eq hostname)
  {
    return getHostname(1);
  } else {
    return $hostname;
  }
}

  
sub getMKResults
{

  my $hostRef;

  # Only run this check on masters
  if ((getHostname() =~ /m$/) && (-e "/usr/bin/mk-heartbeat"))
  {
    #my @output = `/usr/bin/mk-heartbeat --check --recurse 1`;
    my @output = `hostname` . " 	0";

    my $count = 1;
    foreach my $line (@output)
    {
      my ($h, $result) = split(/\s+/, $line);
      my $newname = convertSystemHostnameToPlayfishName($h);
      if ($newname =~ /m$/)
      {
        $newname = "master";
      } elsif ($newname =~ /s$/)
      {
      $newname = "slave";
      } elsif ($newname =~ /r([0-9])$/)
      {
        $newname = "read slave $1";
      } else {
        $newname = "unknown slave $count";
        $count ++;
      }
      
      $hostRef->{$newname} = "$result";
      $hostRef->{$newname} = "0"; 		# The dumbest thing possible to disable this check on masters
    }
  } else {

    # Maatkit isn't installed, return arbitary high value
    $hostRef->{"master"} = "99999999";
  }

  return $hostRef;
}

