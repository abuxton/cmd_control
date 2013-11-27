#!/bin/ksh
############################################################################################
# This script checks for specific network interface
# Nagios exit codes:
# 2=Critical 1=Warning 0=OK 3=Unknown
############################################################################################

print_usage() {
	echo "USAGE: $0 -w|-c -e err_code -i interface"
	echo "-e donotalarm if you do not want alarms"
	echo "-h this help"
}

while [ $# -gt 0 ]
do
    case "$1" in
        -w) warn="yes";;
        -c) crit="yes";;
        -i) intf="$2"
                if [[ $intf = +(-*) ]] || [[ -z $intf ]];then
                /bin/echo "-i requires an argument"
		print_usage
                exit 3
                fi ;shift;;
        -e) err_code="$2"
                if [[ $err_code = +(-*) ]] || [[ -z $err_code ]];then
                /bin/echo "-e requires an argument"
		print_usage
                exit 3 
                fi ;shift;;
        -h) print_usage
	    exit 3;;
        *) print_usage
            exit 3;;
    esac
    shift
done

if [[ $err_code = "donotalarm" ]]; then
        /bin/echo "Do Not Alarm"
        exit 0
fi

if [[ -z $intf ]]; then
	/bin/echo "Please specify an interface name"
	print_usage
	exit 3
fi

if [[ $crit != "yes" && $warn != "yes" ]]; then
	/bin/echo "Please specify either -w or -c"
	print_usage
	exit 3
fi

if [[ $crit = "yes" && $warn = "yes" ]]; then
	/bin/echo "Please specify either -w or -c"
	print_usage
	exit 3
fi

if [[ -z $err_code ]]; then
	err_code="null"
fi


###### Get values ######
line=`/sbin/ifconfig $intf | grep UP | wc -l`
line=`echo $line | sed 's/ //'`

if [[  $line != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of command 'ifconfig' is not numeric. Can not proceed further"
exit 3;
fi

###### Optional return results #######
if [[ $crit = "yes" && $line -eq 0 ]]; then
	/bin/echo "CRITICAL Interface $intf down or does not exist::$err_code::critical=$crit,warn=$warn::$intf=DOWN | $intf=2"
	exit 2
elif [[ $warn = "yes" && $line -eq 0 ]]; then
	/bin/echo "WARNING Interface $intf down or does not exist::$err_code::critical=$crit,warn=$warn::$intf=DOWN | $intf=1"
	exit 1
elif [[ $line -gt 0 ]]; then
	/bin/echo "OK Interface $intf up::$err_code::critical=$crit,warn=$warn::$intf=UP | $intf=0"
	exit 0
fi
