#!/bin/ksh
##########################################################################################
# This script checks for percent used NFS disk space 
# Nagios return codes:
# 2 = Major/Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
print_usage() {
	/bin/echo "USAGE: $0 [-w warn -c crit -e err_code] -p partition"
	/bin/echo "NOTE: Non-existing filesystem ie /mount will result in /"
	/bin/echo "-e donotalarm if you do not want alarms"
}
while getopts w:c:e:p:h options; do
	case ${options} in
	w) warn=$OPTARG;;
	c) crit=$OPTARG;;
	e) err_code=$OPTARG;;
	p) partition=$OPTARG;;
	h) print_usage; exit 0;;
	--help) print_usage; exit 0;;
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
if [[ -z $err_code ]];then
        err_code="null"
fi
if [[ ($warn != "null" && $crit != "null") ]]; then
        if [[ $warn -ge $crit ]]; then
	/bin/echo "WARN threshold should be lower than CRITICAL"
        exit 3
        fi
fi

###### Getting values #######
res=`/bin/df |grep $partition | /bin/awk '{printf("%d %d %d %d"),$1,$2,$3,$4}'`
tot=`echo $res | /bin/awk '{print $1}'`
used=`echo $res | /bin/awk '{print $2}'`
avail=`echo $res | /bin/awk '{print $3}'`
tot_mb=$(( tot/1000 ))
used_mb=$(( used/1000 ))
avail_mb=$(( avail/1000 ))
used_p=`echo $res | /bin/awk '{print $4}'`
used_p=`echo $used_p | sed 's/%//'`

###### Return result options #######
if [[ ($crit != "null" && $used_p -ge $crit) ]]; then
		 /bin/echo "NFS CRITICAL::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | used=$used_mb,available=$avail_mb,total=$tot_mb"
		exit 2
elif [[ ($warn != "null" && $used_p -ge $warn) ]]; then
		/bin/echo "NFS WARNING::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | used=$used_mb,available=$avail_mb,total=$tot_mb"
		exit 1
elif [[ ($used_p -lt $warn || $used_p -lt $crit) ]]; then
		/bin/echo "NFS OK::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | used=$used_mb,available=$avail_mb,total=$tot_mb"
		exit 0
fi
if [[ $# -le 2 ]]; then
        /bin/echo "none::::::partition=$partition,partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | used=$used_mb,available=$avail_mb,total=$tot_mb"
        exit 0
fi
exit 3
