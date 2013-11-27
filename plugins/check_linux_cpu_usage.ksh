#!/bin/ksh
##########################################################################################
# This script checks CPU utilization for RHEL AS2.1 
# Nagios return codes:
# 2 = Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
print_usage() {
	/bin/echo "USAGE: $0 -w warn -c crit -e err_code"
	/bin/echo "WARN threshold should be lower than CRITICAL"
}
while getopts w:c:e:h option; do
	case ${option} in
	w) warn=$OPTARG
	   ;;
	c) crit=$OPTARG
	   ;;
	e) err_code="$OPTARG"
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
if [[ -z $warn ]]; then
        warn="null"
fi
if [[ -z $crit ]]; then
        crit="null"
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
        /bin/echo "WARN threshold should be lower than CRITICAL"
        print_usage
        exit 3
        fi
fi

if [[ -z $err_code ]];then
        err_code="null"
fi

####### Getting values #########
rel=`cat /etc/redhat-release`
if [[ $rel = *Pensacola* ]]; then
	vmout=`/usr/bin/vmstat 1 4 | tail -3 | awk '{US+=$14}{SYS+=$15}{ID+=$16}{print SYS+US,US,SYS,ID}' | tail -1 | awk '{printf("%d %d %d %d"),$1/3,$2/3,$3/3,$4/3}'`
else
	vmout=`/usr/bin/vmstat 1 4 | tail -3 | awk '{US+=$13}{SYS+=$14}{ID+=$15}{print SYS+US,US,SYS,ID}' | tail -1 | awk '{printf("%d %d %d %d"),$1/3,$2/3,$3/3,$4/3}'`
fi
used=`echo $vmout | awk '{print $1}'`
user=`echo $vmout | awk '{print $2}'`
sys=`echo $vmout | awk '{print $3}'`
idle=`echo $vmout | awk '{print $4}'`

if [[  $used   != +([0-9]) ]] || [[  $user   != +([0-9]) ]] || [[  $sys   != +([0-9]) ]] || [[  $idle   != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output is not numeric. Can not proceed further"
exit 3;
fi


####### Return result options  #######
if [[ $crit != "null" && $used -ge $crit ]];then
	/bin/echo "CPU CRITICAL::$err_code::warn=$warn,critical=$crit::used=$used,user=$user,system=$sys,idle=$idle | used=$used, user=$user, system=$sys, idle=$idle"
	exit 2;
elif [[ $warn != "null" && $used -ge $warn ]];then 
	/bin/echo  "CPU  WARNING::$err_code::warn=$warn,critical=$crit::used=$used,user=$user,system=$sys,idle=$idle | used=$used, user=$user, system=$sys, idle=$idle"
	exit 1;
else 
	/bin/echo "CPU OK::$err_code::warn=$warn,critical=$crit::used=$used,user=$user,system=$sys,idle=$idle | used=$used, user=$user, system=$sys, idle=$idle"
	exit 0;
fi
if [[ $# -eq 0 ]]; then
        /bin/echo "none::::::used=$used,user=$user,system=$sys,idle=$idle | used=$used, user=$user, system=$sys, idle=$idle"
        exit 0
fi
