#!/bin/ksh
#######################################################################
# Script that checks CPU Utilization for a given process
# Nagios Exit Codes: 
# 2=Critical/Major Event 1=Warning Event 0=Clear Event 3=Unknown Event
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

cpu=`ps aux | grep "$proc" | grep -v grep | awk '{CPU += $3} {print CPU}' | tail -1`
mem=`ps aux | grep "$proc" | grep -v grep | awk '{MEM += $4} {print MEM}' | tail -1`

mem=$(printf %.0f $mem)
cpu=$(printf %.0f $cpu)

if [[ $cpubool == "1" ]]; then
   cpunumb=`/bin/cat /proc/cpuinfo|/bin/grep '^processor'|/usr/bin/wc -l|sed -e 's/  *$//'` 2> /dev/null
   if [[ $cpunumb -eq 0 ]]; then
      /bin/echo "Access to /proc/cpuinfo failed"
      exit 3
   else 
      cpu=$(($cpu/$cpunumb))
   fi
fi

if [[ ($crit != "null" && $cpu -ge $crit) ]]; then
   /bin/echo "Process CPU Utilization CRITICAL::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem"
   exit 2
elif [[ ($warn != "null" && $cpu -ge $warn) ]]; then
   /bin/echo "Process CPU Utilization WARNING::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem"
   exit 1
else
  /bin/echo "Process CPU Utilization OK::$err_code::warn=$warn,critical=$crit::process=$proc,cpu_percent=$cpu,mem_percent=$mem|cpu_percent=$cpu, mem_percent=$mem"
  exit 0
fi
