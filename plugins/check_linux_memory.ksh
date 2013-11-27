#!/bin/ksh
#######################################################################
# Script Measures Physical Mem % usage
# Free command is same for all versions of redhat 
# Nagios exit return codes:
# 2=Critical Event, 1=Warning Event, 0=OK Event, 3=Unknown Event
#######################################################################
print_usage() {
	echo "This plugin measures physical memory usage percent"
        echo "USAGE: $0 -w warn -c crit -e err_code"
	echo "WARN threshold should be lower than CRITICAL"
	echo "-e donotalarm if you do not want alarms"
}
while getopts w:c:e:h option; do
	case ${option} in
	w) warn=$OPTARG
	   ;;
	c) crit=$OPTARG
	   ;;
	e) err_code=$OPTARG
	   ;;
	h) print_usage
	   exit 3
	   ;;
	--help) print_usage
	   exit 3
	   ;;
	\?) print_usage
	   exit 3
	   ;;
	esac
done

if [[ $err_code = "donotalarm" ]]; then
        /bin/echo "Do Not Alarm"
        exit 0
fi

if [[ -z $warn ]]; then
	warn="null"
fi

if [[ -z $crit ]]; then
	crit="null"
fi

if [[ -z $err_code ]];then
	err_code="null"
fi

if [[  ($warn != "null" && $warn != +([0-9])) ]]; then
/bin/echo  "-w should be an integer"
print_usage
exit 3;
fi

if [[  ($crit != "null" && $crit != +([0-9])) ]]; then
/bin/echo  "-c should be an integer"
print_usage
exit 3;
fi

if [[ ($warn != "null" && $crit != "null") ]]; then
	if [[ $warn -ge $crit ]]; then
        print_usage
        exit 3
	fi
fi

###### Getting values #######
free=`/usr/bin/free -o`
mem=`echo "$free" | grep -i Mem | awk '{printf("%d %d %d %d %d %d"), $2, $3, $4, $5, $6, $7}'`

total=`echo $mem | awk '{print $1}'`
used=`echo $mem | awk '{print $2}'`
free=`echo $mem | awk '{print $3}'`
shared=`echo $mem | awk '{print $4}'`
buf=`echo $mem | awk '{print $5}'`
cache=`echo $mem | awk '{print $6}'`

if [[ $total != +([0-9]) ]] || [[ $used != +([0-9]) ]] || [[ $free != +([0-9]) ]] || [[ $shared != +([0-9]) ]] || [[ $buf != +([0-9]) ]] || [[ $cache != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of 'free' command is not numeric. Can not proceed further"
exit 3;
fi

used_minus=$(echo "$used - $cache - $buf" | bc)
free_plus=$(echo "$free + $cache + $buf" | bc)

used_p=$(echo "scale=2; $used_minus/$total*100" | bc)
free_p=$(echo "scale=2; $free_plus/$total*100" | bc)
used_p=`echo $used_p | sed 's/\.00//'`
free_p=`echo $free_p | sed 's/\.00//'`

if [[ $used_p != +([0-9]) ]] || [[ $free != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of 'free' command is not numeric. Also check if 'bc' command is available. Can not proceed further"
exit 3;
fi

used_mb=$(echo "scale=2; $used_minus/1024" | bc)
total_mb=$(echo "scale=2; $total/1024" |bc)

###### Return result options #######

if [[ ($crit != "null" && $used_p -ge $crit) ]]; then
       	/bin/echo "Memory CRITICAL::$err_code::warn=$warn,critical=$crit::used=$used_p%,free=$free_p%,total=$total_mb mb | used=$used_mb"
       	exit 2
elif [[ ($warn != "null" && $used_p -ge $warn) ]];then
       	/bin/echo "Memory WARNING::$err_code::warn=$warn,critical=$crit::used=$used_p%,free=$free_p%,total=$total_mb mb | used=$used_mb"
       	exit 1
else 
       	/bin/echo "Memory OK::$err_code::warn=$warn,critical=$crit::used=$used_p%,free=$free_p%,total=$total_mb mb | used=$used_mb" 
       	exit 0
fi
