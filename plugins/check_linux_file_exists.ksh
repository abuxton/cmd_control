#!/bin/ksh
################################################################################
# This script checks for file existence
# Nagios return codes: 2=Critical 1=Warning 0=OK 3=Unknown
################################################################################
print_usage() {
	/bin/echo "USAGE: $0 [-w if_exists or if_not_exists] [-c if_exists or if_not_exists] -e err_code -f file"
	/bin/echo "-e donotalarm if you do not want alarms"
}
while getopts w:c:e:f:h options; do
	case ${options} in 
	w) warn="$OPTARG";;
	c) crit="$OPTARG";;
	e) err_code=$OPTARG;;
	f) file=$OPTARG;;
	h) print_usage; exit 0;;
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
######### Optional return results #########
if [[ ($crit = "if_exists" && -e $file) ]]; then
	/bin/echo "CRITICAL::$err_code::warn=$warn,critical=$crit::File $file exists | file_exist=0"
	exit 2
elif [[ ($crit = "if_not_exists" && ! -e $file) ]]; then
	/bin/echo "CRITICAL::$err_code::warn=$warn,critical=$crit::File $file does not exist | file_not_exists=0"
	exit 2
fi
if [[ ($warn = "if_exists" && -e $file) ]]; then
	/bin/echo "WARNING::$err_code::warn=$warn,critical=$crit::File $file exists | file_exist=0"
	exit 1
elif [[ ($warn = "if_not_exists" && ! -e $file) ]]; then
	/bin/echo "WARNING::$err_code::warn=$warn,critical=$crit::File $file does not exist | file_not_exists=0"
	exit 1
fi
if [[ ($crit = "if_exists" || $warn = "if_exists") ]]; then
	if [[ ! -e $file ]]; then
		/bin/echo "OK::$err_code::warn=$warn,critical=$crit::File $file does not exist | file_not_exists=1"
		exit 0
	fi
elif [[ ($crit = "if_not_exists" || $warn = "if_not_exists") ]]; then
	if [[ -e $file ]]; then
		/bin/echo "OK::$err_code::warn=$warn,critical=$crit::File $file exists | file_exists=1"
		exit 0
	fi
fi
exit 3
