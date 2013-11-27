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

pid=`ps aux | grep "$proc" | grep -v grep | grep -v "bin/monitor" | grep -v check_process_cpumem.ksh | awk '{PID = $2} {print PID}' | tail -1`
cpu=`top -b -n 1 -p $pid | grep $pid | tail -1 | awk '{CPU += $9} {print CPU}'`
# cpu=`ps aux | grep "$proc" | grep -v grep | grep -v "bin/monitor" | grep -v check_process_cpumem.ksh | awk '{CPU += $3} {print CPU}' | tail -1`
mem=`ps aux | grep "$proc" | grep -v grep | grep -v "bin/monitor" | grep -v check_process_cpumem.ksh | awk '{MEM += $4} {print MEM}' | tail -1`
vsz=`ps aux | grep "$proc" | grep -v grep | grep -v "bin/monitor"| grep -v check_process_cpumem.ksh | awk '{VSZ = $5} {print VSZ}'`

cpubool=0
if [[ $cpubool == "1" ]]; then
   cpunumb=`/bin/cat /proc/cpuinfo|/bin/grep '^processor'|/usr/bin/wc -l|sed -e 's/  *$//'` 2> /dev/null
   if [[ $cpunumb -eq 0 ]]; then
      /bin/echo "Access to /proc/cpuinfo failed"
      exit 3
   else
      cpu=$(($cpu/$cpunumb))
   fi
fi

mem=$(printf %.2f $mem)
cpu=$(printf %.2f $cpu)


if [[ ($crit != "null" && $cpu -ge $crit) ]]; then
   /bin/echo "Process CPU Utilization CRITICAL::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem, vsz=$vsz"
   exit 2
elif [[ ($warn != "null" && $cpu -ge $warn) ]]; then
   /bin/echo "Process CPU Utilization WARNING::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem, vsz=$vsz"
   exit 1
else
  /bin/echo "Process CPU Utilization OK::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem, vsz=$vsz"
  exit 0
fi


