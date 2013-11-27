#!/bin/ksh
#######################################################################
# Script that checks CPU Utilization for a given process
# Nagios Exit Codes:
# 2=Critical/Major Event 1=Warning Event 0=Clear Event 3=Unknown Event

# Sep-15-2009: Modified cpu and mem percent to return 1 decimal place
# Oct 8 - modify cpu to get from top instead of ps

#######################################################################
print_usage() {
        /bin/echo "USAGE: $0 [-w percent_value] [-c percent_value] [-e err_code] -p proc [-r]"
        /bin/echo "-r : Use this switch if the CPU count is to be considered for CPU Utilization computation. Mostly, preferred"
}
while getopts w:c:e:p:hr options; do
        case ${options} in
        w) warn=$OPTARG;;
        c) crit=$OPTARG;;
        e) err_code=$OPTARG;;
        p) proc=${OPTARG};;
        r) cpubool="1";;
        h) print_usage; exit 0;;
        --help) print_usage; exit 0;;
        \?) print_usage; exit 0;;
        esac
done

if [[ $proc == '' ]]; then
   /bin/echo "Process name is missing"
   print_usage
   exit 3
fi

if [[ -z $warn ]]; then
   warn="null"
fi
if [[ -z $crit ]]; then
   crit="null"
fi
if [[ ($warn != "null" && $crit != "null") ]]; then
   if [[ $warn -ge $crit ]]; then
      /bin/echo "Warning threshold must be lesser than Critical threshold"
      print_usage
      exit 3
   fi
fi
if [[ -z $err_code ]]; then
   err_code="null"
fi

#this should be done in one command but we are in a rush to complete this monitoring
#ps returns a modified cpu% (check the man page), the top one is what we're looking for
#we need to get the pid first because top doesn't seem to return any procs not started by the nagios user when run via nrpe
pid=`ps aux | grep -E $proc | grep -v grep | grep -v "bin/monitor" | grep -v check_process_stats.ksh | awk '{PID = $2} {print PID}' | tail -1`
cpu=`top -b -n 1 -p $pid | grep $pid | tail -1 | awk '{CPU += $9} {print CPU}'`
mem=`ps -eo %mem,vsz,etime,command | grep -E "$proc" | grep -v grep | grep -v "bin/monitor" | grep -v check_process_stats.ksh | awk '{MEM = $1} {print MEM}'`
vsz=`ps -eo %mem,vsz,etime,command | grep -E "$proc" | grep -v grep | grep -v "bin/monitor"| grep -v check_process_stats.ksh | awk '{VSZ = $2} {print VSZ}'`
etime=`ps -eo %mem,vsz,etime,command | grep -E "$proc" | grep -v grep | grep -v "bin/monitor"| grep -v check_process_stats.ksh | awk '{ETIME = $3} {print ETIME}'`
rss=`ps -eo %mem,vsz,etime,rss,command | grep -E "$proc" | grep -v grep | grep -v "bin/monitor"| grep -v check_process_stats.ksh | awk '{RSS = $4} {print RSS}'`

if [[ ($crit != "null" && $cpu -ge $crit) ]]; then
   /bin/echo "Process CPU Utilization CRITICAL::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem, vsz=$vsz, etime=$etime, rss=$rss"
   exit 2
elif [[ ($warn != "null" && $cpu -ge $warn) ]]; then
   /bin/echo "Process CPU Utilization WARNING::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem, vsz=$vsz, etime=$etime, rss=$rss"
   exit 1
else
  /bin/echo "Process CPU Utilization OK::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem, vsz=$vsz, etime=$etime, rss=$rss"
  exit 0
fi

