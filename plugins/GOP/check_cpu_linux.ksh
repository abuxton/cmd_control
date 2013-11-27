#!/bin/ksh
##########################################################################################
# This script checks CPU utilization for RHEL WS3 and AS4.
# Nagios return codes:
# 2 = Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
print_usage() {
	/bin/echo "USAGE: $0 -w warn -c crit -e err_code"
	/bin/echo "WARN threshold should be lower than CRITICAL"
}
while getopts w:c:e: option; do
	case ${option} in
	w) warn=$OPTARG
	   ;;
	c) crit=$OPTARG
	   ;;
	e) err_code="$OPTARG"
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
if [[ ($warn != "null" && $crit != "null") ]]; then
        if [[ $warn -ge $crit ]]; then
        print_usage
        exit 3
        fi
fi

function average {
	case "$2" in
		"%idle") field=8
        		checkForStealColumn=$(echo "$1" | grep 'steal')
        		if [[ ($checkForStealColumn != "") ]]; then
                		field=9
        		fi
		;;
		"%user") field=4;;
		"%system") field=6;;
	esac

	# Average the last X results and round to the nearest whole number
	printf %.0f $(echo "$1" | awk "{print \$$field}" | tail -n $(($3 + 1)) | head -n $3 | awk "{s+=\$1} END {print s/$3}")
}

####### Getting values #########
sarout="$( sar )"
# Make sure we have enough data. Sar rolls its logs over at midnight
# There will be no data during that time. This is a special case for that.
if [[ $(echo "$sarout" | grep -v "Linux" | grep -v "Average" | grep "all" | tail -n 6 | head -n 5 | wc -l) -lt 5 ]]; then
    sarout="$(sar 1 5)"
fi	
used=$( average "$sarout" "%idle" 5  | awk '{s=$1} END {print 100-s}' )
user=$( average "$sarout" "%user" 5 )
sys=$( average "$sarout" "%system" 5 )
idle=$( average "$sarout" "%idle" 5 ) 

####### Return result options  #######
if [[ $# -eq 0 ]]; then
        /bin/echo "none:::used=$used,user=$user,system=$sys,idle=$idle | used="$used"%,user="$user"%,system="$sys"%,idle="$idle"%"
        exit 0
fi
if [[ $crit != "null" && $used -ge $crit ]];then
	/bin/echo "CPU CRITICAL:$err_code:warn=$warn,critical=$crit:used=$used%,user=$user%,system=$sys%,idle=$idle% | used="$used"%,user="$user"%,system="$sys"%,idle="$idle"%"
	exit 2
elif [[ $warn != "null" && $used -ge $warn ]];then 
	/bin/echo  "CPU WARNING:$err_code:warn=$warn,critical=$crit:used=$used%,user=$user%,system=$sys%,idle=$idle%  | used="$used"%,user="$user"%,system="$sys"%,idle="$idle"%"
	exit 1
elif [[ ($used -lt $warn || $used -lt $crit) ]];then
	/bin/echo "CPU OK:$err_code:warn=$warn,critical=$crit:used=$used%,user=$user%,system=$sys%,idle=$idle%  | used="$used"%,user="$user"%,system="$sys"%,idle="$idle"%"
	exit 0
fi
exit 3
