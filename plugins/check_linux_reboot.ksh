#!/bin/ksh
###################################################################################
# This script checks for system reboot 
# Nagios exit codes:
# 2=Critical 1=Warning 0=OK 3=Unknown
###################################################################################
print_usage() {
	/bin/echo "USAGE: $0 -w|-c -e err_code -t time_in_minutes"
		/bin/echo "-e donotalarm if you do not want alarms"
		/bin/echo "-h. This help."
}

while [ $# -gt 0 ]
	do
		case "$1" in
		-w) warn="yes";;
		-c) crit="yes";;
		-t) time="$2"
			if [[ $time = +(-*) ]] || [[ -z $time ]];then
				/bin/echo "-t requires an argument"
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

if [[ -z $time ]] || [[ $time != +([0-9]) ]]; then
/bin/echo "Please specify time in minutes"
print_usage
exit 3
fi

if [[ -z $err_code ]]; then
err_code="null"
fi

if [[ -z $warn ]]; then
warn="null"
fi

if [[ -z $crit ]]; then
crit="null"
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

###### Get values ######
uptime=`uptime`
#uptime='04:50:11 up 4 min,  1 user,  load average: 0.20, 0.55, 0.27'
#uptime='03:42:20 up 22:56,  1 user,  load average: 0.00, 0.02, 0.00'
days=`/bin/echo $uptime |grep day`

if [ -n "$days" ]; then
no_day=`/bin/echo $days | sed  's/.*up \(.*\) day.*/\1/' `
print "No recent reboot::$err_code::warn=$warn,critical=$crit,time=$time min::uptime=$no_day days| days_up=$no_day "
exit
else
	min=`/bin/echo $uptime |grep min`
	if [ -n "$min" ] ;then
		no_min=`/bin/echo $uptime | sed  's/.*up \(.*\) min.*/\1/' `
		if [[ $no_min = +([0-9]) ]]; then
			if [[ $no_min -le $time ]] ; then
				if [[ $crit = "yes" ]] ; then
					print " Recent reboot::$err_code::warn=$warn,critical=$crit,time=$time min::uptime=0 day . $no_min mins up less than $time| days_up=0 "
					exit 2
				else
					print " Recent reboot::$err_code::warn=$warn,critical=$crit,time=$time min::uptime=0 day . $no_min mins up less than $time| days_up=0 "
					exit 1 
				fi		
			else
				print "No recent reboot::$err_code::warn=$warn,critical=$crit,time=$time min::uptime=0 day . up min greater than $time mins | days_up=0"
				exit 0
			fi
		else
			print "No recent reboot::$err_code::warn=$warn,critical=$crit,time=$time min::uptime=0 day . up min greater than $time mins| days_up=0"
			exit
		fi
	else
		print "No recent reboot::$err_code::warn=$warn,critical=$crit,time=$time min::uptime=0 day . up min greater than $time mins| days_up=0"	
		exit


	fi
fi
