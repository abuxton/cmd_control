#!/bin/bash
#########################################################################################
# This script averages response times from server logs.
# Nagios return codes:
# 2 = Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event ###########################################################################################
debug=0
print_usage() {
	/bin/echo "USAGE: $0 -w warn -c crit -e err_code -n lines_to_check"
	/bin/echo "WARN threshold should be lower than CRITICAL"
}
while getopts w:c:e:n: option; do
	case ${option} in
	w) warn=$OPTARG
	   ;;
	c) crit=$OPTARG
	   ;;
	e) err_code="$OPTARG"
	   ;;
	n) lines_to_check="$OPTARG"
           ;;
	h) print_usage
	   exit 0
	   ;;
	--help) print_usage
	   exit 0
	   ;;
	\?) print_usage
	   exit 3
	   ;;
	esac
done
if [[ -z $warn ]]; then
        warn="null"
fi
if [[ -z $crit ]]; then
        crit="null"
fi
if [[ -z $err_code ]];then
        err_code="null"
fi
if [[ -z $lines_to_check ]];then
        lines_to_check=10
fi
if [[ ($warn != "null" && $crit != "null") ]]; then
        if [[ $warn -ge $crit ]]; then
        print_usage
        exit 3
        fi
fi

# Ask if Keymaster server
if [ -d /opt/ea/nova/keymaster ] ; then
   httpLogRoot="/opt/ea/nova/keymaster"
   httpLogName="httpd_access.log"
else #default Nucleus Server
    httpLogRoot="/opt/ea/nova/nucleus"
   httpLogName="httpd_access.log"
fi

search_path=$httpLogRoot"/serv/"$httpLogName
#if [[ debug -eq 1 ]] ; then 
   #echo "Search Path " $search_path
#fi

####### Getting values #########
AllResponseTimes="$(tail -$(($lines_to_check+1)) $search_path | grep -io '[0-9]*ms' | awk '/[1-9]/' | sed s/..$//)"
# Get count of actual lines we got. (Log file may have less than requested) 
TotalLines="$(echo "$AllResponseTimes" | wc -l)"
AllResponseTimes="$(echo "$AllResponseTimes" | head -$(($TotalLines-1)))"
Total=$(echo "$AllResponseTimes" | (tr '\n' +; echo 0) | bc) 
Average=$(echo "scale=1; ($Total / $TotalLines)" | bc -l) 
IntAverage=${Average/\.*}

####### Return result options  #######
if [[ $crit = "null" && $warn = "null"  ]]; then
        /bin/echo "Response Average::responseaverage=$Average"
        exit 0
fi
if [[ $crit != "null" && $(echo "$IntAverage > $crit"|bc) -eq 1 ]];then
	/bin/echo "Response Average CRITICAL: $err_code - :responseaverage=$Average"
	exit 2
elif [[ $warn != "null" && $(echo "$IntAverage > $warn"|bc) -eq 1 ]];then 
	/bin/echo  "Response Average WARNING: $err_code - :responseaverage=$Average"
	exit 1
elif [[ ($(echo "$IntAverage < $warn"|bc) -eq 1 || $(echo "$IntAverage < $crit"|bc) -eq 1) ]];then
	/bin/echo "Response Average OK: 200 OK - :responseaverage=$Average"
	exit 0
fi
exit 3
