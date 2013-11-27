#!/bin/ksh
##################################################################################
# Script checks for file update and alarm if file is older than time threshold
# Exit codes: 2=Critical 1=Warning 0=OK 3=Unknown
################################################################################## 
print_usage() {
	echo "USAGE: $0 -w|-c -e err_code -f path_to_file -t minutes"
	echo "-e donotalarm if you do not want alarms"
}
while getopts wce:f:t:h options; do
	case ${options} in
	w) warn="yes";;
	c) crit="yes";;
	e) err_code=$OPTARG;;
	f) file=$OPTARG;;
	t) time=$OPTARG;;
	h) print_usage; exit 0;;
	help) print_usage; exit 0;;
	\?) print_usage; exit 0;;
	esac
done
if [[ $err_code = "donotalarm" ]]; then
        /bin/echo "Do Not Alarm"
        exit 0
fi
if [[ ! -a $file ]]; then
	echo "UNKNOWN:::::File does not exist"
	exit 3
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

####### Get values #######
now=`date +%s`
file_time=`date -r $file +%s`
(( file_age=$now - $file_time ))
(( file_age=$file_age/60 ))
####### Optional return results ########
if [[ ($crit = "yes" && $file_age -gt $time) ]]; then
	/bin/echo "File older than CRITICAL threshold::$err_code::warn=$warn,critical=$crit::file=$file,file_age=$file_age min | file_age=$file_age"
	exit 2
elif [[ ($warn = "yes" && $file_age -gt $time) ]]; then
	/bin/echo "File older than WARNING threshold::$err_code::warn=$warn,critical=$crit::file=$file,file_age=$file_age min | file_age=$file_age"
	exit 1
elif [[ $file_age -le $time ]]; then
	/bin/echo "File age OK::$err_code::warn=$warn,critical=$crit::file=$file,file_age=$file_age min | file_age=$file_age"
	exit 0
elif [[ -z $time ]]; then
	/bin/echo "none::::::file=$file,file_age=$file_age min | file_age=$file_age"
fi
exit 3
