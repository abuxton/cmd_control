#!/bin/ksh
##########################################################################################
# This script checks for network errors
# Nagios return codes:
# 2 = Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event
###########################################################################################
print_usage() {
	/bin/echo "USAGE: $0 -w warn -c crit -e err_code -i interface"
	/bin/echo "WARNING threshold should be lower than CRITICAL"
	/bin/echo "-e donotalarm if you do not want alarms"
}
while getopts w:c:e:i: option; do
	case ${option} in
	w) warn=$OPTARG
	   ;;
	c) crit=$OPTARG
	   ;;
	e) err_code="$OPTARG"
	   ;;
	i) intf="$OPTARG"
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
if [[ -z $intf ]]; then
	print_usage
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

####### Getting values #########
out=`/bin/netstat -i | grep $intf |wc -l`
out=`echo $out | sed 's/ //'`

if [[  $out   != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of command 'netstat' is not numeric. Can not proceed further"
exit 3;
fi

if [[ $out -lt 1 ]]; then
	/bin/echo "Interface $intf does not exist"
	exit 3
fi
out=`/bin/netstat -i | grep $intf | awk '{printf("%d %d"),$5,$9}'`
rx_err=`echo $out | awk '{print $1}'`
tx_err=`echo $out | awk '{print $2}'`


if [[ $rx_err != +([0-9]) ]] || [[ $tx_err != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of command 'netstat' is not numeric. Can not proceed further"
exit 3;
fi

networktrackfile=/usr/local/nagios/$intf.txt
if [ ! -f $networktrackfile ]
then  echo "$rx_err:$tx_err" > $networktrackfile

	if [[ $? != 0 ]]; then
	print "Unknown :: Unable to create trackfile $networktrackfile.";
	exit 3;
	fi

echo "Setting first time value : $rx_err:$tx_err";
exit 3;

else

old_rx_err=`awk -F: '{print $1}' $networktrackfile`;
old_tx_err=`awk -F: '{print $2}' $networktrackfile`;
let dtx_err=tx_err-old_tx_err ;
let drx_err=rx_err-old_rx_err ;
echo "$rx_err:$tx_err" > $networktrackfile

	if [[ $? != 0 ]]; then
	print "Unknown :: Unable to update trackfile $networktrackfile.";
	exit 3;
	fi

fi


####### Return result options  #######
if [[ ($crit != "null" && ($drx_err -ge $crit || $dtx_err -ge $crit)) ]];then
	/bin/echo "Network Errors CRITICAL::$err_code::warn=$warn,critical=$crit::rx_err=$drx_err,tx_err=$dtx_err | rx_err=$drx_err tx_err=$dtx_err"
	exit 2
elif [[ ($warn != "null" && ($drx_err -ge $warn || $dtx_err -ge $warn)) ]];then 
	/bin/echo  "Network Errors WARNING::$err_code::warn=$warn,critical=$crit::rx_err=$drx_err,tx_err=$dtx_err | rx_err=$drx_err tx_err=$dtx_err"
	exit 1
else 
	/bin/echo "Network Errors OK::$err_code::warn=$warn,critical=$crit::rx_err=$drx_err,tx_err=$dtx_err | rx_err=$drx_err tx_err=$dtx_err"
	exit 0
fi

