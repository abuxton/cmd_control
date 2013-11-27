#!/bin/bash


print_usage() {
	/bin/echo "USAGE: $0 -w warn -c crit -n name_of_call -s name_of_service -t threshold (Y/N) "
	/bin/echo "WARN threshold should be lower than CRITICAL"
}

err_code="500"
debug=0


while getopts w:c:n:s:t: option; do
  case ${option} in
    w) warn=$OPTARG
	   ;;
    c) crit=$OPTARG
	   ;;
    n) name_of_call="$OPTARG"
       ;;   
    s) name_of_service="$OPTARG"
           ;;
    t) threshold="$OPTARG"
       ;;
    h) print_usage
	   exit 0
	   ;;
    --help) print_usage
	   exit 0
	   ;;
    \?) print_usage
	   exit 3
	   ;;
	esac
done

if [[ -z $threshold ]]; then
        threshold="Y"
fi
if [[ -z $warn ]]; then
        warn="null"
fi
if [[ -z $crit ]]; then
        crit="null"
fi
if [[ -z $name_of_call ]];then
        print_usage
        exit 3
fi
if [[ ($warn != "null" && $crit != "null") ]]; then
        if [[ $warn -ge $crit ]]; then
        print_usage
        exit 3
        fi
fi

#default to nucleus standard
statsLogFile="/opt/ea/nova/nucleus/serv/stats.log"
#statsLogFile="/cygdrive/c/eas/tmp/pogo_jumper/monitor/stats.log"

if [[ ($name_of_service = "access") ]]; then
	statsLogFile="/opt/ea/nova/access/serv/stats.log"
fi

###### Getting values #########

#line=$(tail -9 $statsLogFile | grep $name_of_call) # this extracts the 5 min transaction count from the line that has the matching APIString
#echo $line

line=$(tail -1 $statsLogFile) # Line to check the last minute grabbed 

#Want to build a REGEX timestamp and the API String
#Let's take the substring that contains the timestamp, add .* and add the API String
#	04/08/11 19:44
timestmp=$(echo "${line:0:14}.*$name_of_call")
if [[ debug -eq 1 ]] ; then
   echo $timestmp
fi
#grep the file for the above built string
line=$(grep "$timestmp" $statsLogFile) # this extracts the 5 min transaction count from the line that has the matching APIString
if [[ debug -eq 1 ]] ; then
   echo $line
fi

# If no output line then return 0
if [ -z "$line" ] ; then 
    transactionCount=0
	responseAverage=0
else
	#            the 9th item      | cut off last number |  cut off 1st num | cut  leading /  | cut trailing
	transactionCount=$(echo $line | awk '{print $9 }' | sed s/[0-9]*,$// | sed s/^[0-9]*// | sed s/^.// | sed s/.$//)
	# this extracts the 5 min response average from the line that has the matching APIString
	#            the 16th item      | cut off last number |  cut off 1st num | cut  leading /  | cut trailing
	responseAverage=$(echo $line | awk '{print $16 }' | sed s/[0-9]*,$// | sed s/^[0-9]*// | sed s/^.// | sed s/.$//)
fi
output="trasactionCount=$transactionCount, responseAverage=$responseAverage"


###### Return result options  #######
if [[ ($threshold = "Y") ]]; then
	if [[ $crit = "null" && $warn = "null"  ]]; then
			/bin/echo "GOPStatsCollection OK 200 ::$output |Error:0"
			exit 0
	fi
	if [[ $crit != "null" && $(echo "$responseAverage > $crit"|bc) -eq 1 ]];then
		/bin/echo "GOPStatsCollection CRITICAL $err_code ::$output |Error:2"
		exit 2
	elif [[ $warn != "null" && $(echo "$responseAverage > $warn"|bc) -eq 1 ]];then 
		/bin/echo  "GOPStatsCollection WARNING $err_code ::$output |Error:1"
		exit 1
	elif [[ ($(echo "$responseAverage < $warn"|bc) -eq 1 || $(echo "$IntAverage < $crit"|bc) -eq 1) ]];then
		/bin/echo "GOPStatsCollection OK 200 ::$output |Error:0"
		exit 0
	fi
	/bin/echo "GOPStatsCollection |Error:3"
	exit 3
else
	/bin/echo "trasactionCount:$transactionCount responseAverage:$responseAverage"
fi

