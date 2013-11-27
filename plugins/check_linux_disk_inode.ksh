#!/bin/ksh
##########################################################################################
# This script checks for disk inode
# Nagios return codes:
# 2 = Major/Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
print_usage() {
        /bin/echo "USAGE: $0 -w warn_threshold -c critical_threshold -e err_code -p partition"
	/bin/echo "-e donotalarm if you do not want alarms"
}
while getopts w:c:e:p:h options; do
        case ${options} in
        w) warn=$OPTARG;;
        c) crit=$OPTARG;;
        e) err_code=$OPTARG;;
        p) partition=$OPTARG;;
        h) print_usage; exit 3;;
        --help) print_usage; exit 3;;
        \?) print_usage; exit 3;;
        esac
done

if [[ $err_code = "donotalarm" ]]; then
        /bin/echo "Do Not Alarm"
        exit 0
fi

if [[ -z $partition ]]; then
	print "please specify a partition"
        print_usage
	exit 3;
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
        /bin/echo "WARN threshold should be lower than CRITICAL"
	print_usage
        exit 3
        fi
fi

x=`df -k $partition`
val=`echo $?`
if [[ $val != 0 ]]; then
        /bin/echo "BROKEN MONITOR::ESM00016::::Got error for partition $partition | result=3"
        exit 3
fi


###### Getting values #######

res=`/bin/df -i "$partition" | tail -1 | /bin/awk '{printf("%d %d %d %d"),$2,$3,$4,$5}'`
tot=`/bin/echo $res | /bin/awk '{print $1}'`
used=`/bin/echo $res | /bin/awk '{print $2}'`
avail=`/bin/echo $res | /bin/awk '{print $3}'`
used_p=`/bin/echo $res | /bin/awk '{print $4}'`
used_p=`/bin/echo $used_p | sed 's/%//'`

if [[  $tot   != +([0-9]) ]] || [[  $used   != +([0-9]) ]] || [[  $avail   != +([0-9]) ]] || [[  $used_p   != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of df is not numeric. Can not proceed further"
exit 3;
fi

###### Return result options #######
if [[ ($crit != "null" && $used_p -ge $crit) ]]; then
	/bin/echo "Disk Inodes CRITICAL::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used,available=$avail,total=$tot | used=$used, available=$avail, total=$tot"
        exit 2
elif [[ ($warn != "null" && $used_p -ge $warn) ]]; then
        /bin/echo "Disk Inodes WARNING::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used,available=$avail,total=$tot | used=$used, available=$avail, total=$tot"
        exit 1
else 
        /bin/echo "Disk Inodes OK::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used,available=$avail,total=$tot | used=$used, available=$avail, total=$tot"
        exit 0
fi
