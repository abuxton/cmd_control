#!/bin/ksh
##########################################################################################
# This script uses free -o for swap values and result is based on MB FREE/AVAILABLE
# Nagios return codes:
# 2 = Major/Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
print_usage() {
        /bin/echo "USAGE: $0 -w warn -c crit -e err_code"
	/bin/echo "WARN threshold should be higher than CRITICAL"
	/bin/echo "-h , --help - This help"
}
while getopts w:c:e:h options; do
        case ${options} in
        w) warn=$OPTARG;;
        c) crit=$OPTARG;;
        e) err_code=$OPTARG;;
        h) print_usage; exit 3;;
        \?) print_usage; exit 3;;
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
        if [[ $warn -le $crit ]]; then
        /bin/echo "WARN threshold should be higher than CRITICAL"
        exit 3
        fi
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

###### Getting values #######
swap=`/usr/bin/free -o | grep -i swap | awk '{printf("%d %d %d"), $2, $3, $4}'`
total=`echo $swap | awk '{print $1}'`
used=`echo $swap | awk '{print $2}'`
free=`echo $swap | awk '{print $3}'`

if [[ $total != +([0-9]) ]] || [[ $used != +([0-9]) ]] || [[ $free != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of command 'free' is not numeric. Can not proceed further"
exit 3;
fi

if [[ $total = 0 ]]; then
        /bin/echo "Total swap is 0 ... swap not configured"
        exit 3
fi

##### Optional results #####
if [[ ($crit != "null" && $free -le $crit) ]]; then
	echo "Swap CRITICAL:$err_code:warn=$warn,critical=$crit:total=$total,used=$used mb,free=$free mb | total=$total used=$used"
	exit 2
elif [[ ($warn != "null" && $free -le $warn) ]]; then
	echo "Swap WARNING:$err_code:warn=$warn,critical=$crit:total=$total,used=$used mb,free=$free mb | total=$total used=$used" 
	exit 1
else
	echo "Swap OK:$err_code:warn=$warn,critical=$crit:total=$total,used=$used mb,free=$free mb | total=$total used=$used" 
	exit 0
fi
