#!/bin/ksh
##########################################################################################
# This script checks for percent used disk space 
# Nagios return codes:
# 2 = Major/Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
comusr='nagios'
badcount=1
print_usage() {
	echo "USAGE: $0 [-w warn -c crit -e err_code -m] -p partition"
        echo "Argument -m is of relevance in cases wherein the partition is a Remote Mount Point. Skipping this argument can result in erroneous monitoring"
}
#Check for potential defunct processes
check_process() {
   pscom=`ps auxww | grep -i "df -k $partition" | grep -v grep | grep -i $comusr | wc -l`
   if [[ $pscom -ge $badcount ]]; then
         echo "MOUNT HUNG CRITICAL::$err_code::warn=$warn,critical=$crit::Investigate Mount Point $partition hung,partition=$partition | result=-1"
         exit 2
   fi
}

while getopts w:c:e:p:mh options; do
	case ${options} in
	w) warn=$OPTARG;;
	c) crit=$OPTARG;;
	e) err_code=$OPTARG;;
	p) partition=$OPTARG;;
        m) mount=1;;
	h) print_usage; exit 0;;
	--help) print_usage; exit 0;;
	\?) print_usage; exit 0;;
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

check_process

### check if fs exists and find number of fields
x=`df -k $partition 2>/dev/null`
val=`echo $?`
if [[ $val != 0 ]]; then
        /bin/echo "BROKEN MONITOR::ESM00016::::Got error for partition $partition | result=-1"
        exit 3
fi
out=`df -k $partition | tail -1`
fields=`echo $out| awk '{print NF}'`
if [[ $fields -eq 6 ]]; then
        fs="local"
elif [[ $fields -eq 5 ]]; then
        fs="mount"
fi
if [[ $fields  -lt 5 || $fields -gt 6 ]]; then
        echo "BROKEN MONITOR::ESM00016::partition $partition got $fields fields | result=3"
        exit 3
fi
### Get values ###
if [[ $fs = "local" ]]; then
        tot=`echo $out | /bin/awk '{print $2}'`
        used=`echo $out | /bin/awk '{print $3}'`
        avail=`echo $out | /bin/awk '{print $4}'`
        used_p=`echo $out | /bin/awk '{print $5}'`
        disk=`echo $out | /bin/awk '{print $6}'`
elif [[ $fs = "mount" ]]; then
        tot=`echo $out | /bin/awk '{print $1}'`
        used=`echo $out | /bin/awk '{print $2}'`
        avail=`echo $out | /bin/awk '{print $3}'`
        used_p=`echo $out | /bin/awk '{print $4}'`
        disk=`echo $out | /bin/awk '{print $5}'`
fi
tot_mb=$(( tot/1000 ))
used_mb=$(( used/1000 ))
avail_mb=$(( avail/1000 ))
used_p=`echo $used_p | sed 's/%//'`
### check to see if the partion we monitor is a file system or just a directory
if [[ ${partition} != ${disk} ]]; then
        if [[ -n ${mount} ]]; then #Its a potential Mount Point. Alarm if it ceases to exist !
                echo "Mount Point CRITICAL::$err_code::warn=$warn,critical=$crit::Mount file system Missing,partition=$partition | result=-1"
                exit 2;
        else #This is the Normal Case
        	echo "Partition $partition is pointing to $disk file system"
        	exit 0
	fi
fi
###### Return result options #######
if [[ ($crit != "null" && $avail_mb -le $crit) ]]; then
        echo "DISK SPACE CRITICAL::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | $partition=$used_mb, available=$avail_mb, total=$tot_mb"
        exit 2
elif [[ ($warn != "null" && $avail_mb -le $warn) ]]; then
        echo "DISK SPACE WARNING::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | $partition=$used_mb, available=$avail_mb, total=$tot_mb"
        exit 1
elif [[ ($avail_mb -gt $warn || $avail_mb -gt $crit) ]]; then
        echo "DISK SPACE OK::$err_code::warn=$warn,critical=$crit::partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb| $partition=$used_mb, available=$avail_mb, total=$tot_mb"
        exit 0
fi
if [[ $# -le 2 ]]; then
        echo "none::::::partition=$partition,partition=$partition,used%=$used_p,used=$used_mb mb,available=$avail_mb mb,total=$tot_mb mb | $partition=$used_mb, available=$avail_mb, total=$tot_mb"
        exit 0
fi
exit 3
