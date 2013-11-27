#!/bin/ksh
##################################################################################
# This script checks for opened network connections
# Nagios exit codes:
# 2=Critical 1=Warning 0=OK 3=Unknown
##################################################################################
print_usage() {
	echo "USAGE: $0 -w warn_threshold -c critical_threshold -e err_code"
	echo "-e donotalarm if you do not want alarms"
}
while getopts w:c:e: option; do
	case $option in
	w) warn=$OPTARG;;
	c) crit=$OPTARG;;
	e) err_code=$OPTARG;;
	h) print_usage; exit 0;;
	help) print_usage; exit 0;;
	\?) print_usage; exit 0;;
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
if [[ -z $err_code ]]; then
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

if [[ $warn != "null" && $crit != "null" ]]; then
	if [[ $warn -ge $crit ]]; then
		/bin/echo "Warning threshold should be lower than Critical"
		exit 0
	fi
fi

if [[ ! -f /bin/netstat ]]; then
/bin/echo "Unknown error ::$err_code::warn=$warn,critical=$crit::netstat command not found"
exit 3;
fi

####### Getting values #######
connections=`/bin/netstat -ne | grep -i established | wc -l`
conn=`echo $connections | sed 's/ //'`

if [[  $conn   != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of 'netstat' command is not numeric. Can not proceed further"
exit 3;
fi

####### Optional return results #######
if [[ $crit != "null" && $conn -ge $crit ]]; then
	/bin/echo "Network connections exceeded CRITICAL threshold::$err_code::warn=$warn,critical=$crit::connections=$conn | connections=$conn"
	exit 2
elif [[ $warn != "null" && $conn -ge $warn ]]; then
	/bin/echo "Network connections exceeded WARNING threshold::$err_code::warn=$warn,critical=$crit::connections=$conn | connections=$conn"
	exit 1
else
	/bin/echo "Network connections OK::$err_code::warn=$warn,critical=$crit::connections=$conn | connections=$conn"
	exit 0
fi
