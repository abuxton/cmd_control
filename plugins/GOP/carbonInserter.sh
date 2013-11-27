#!/bin/bash
##########################################################################################
# This script collects production transaction totals from nova clusters as defined in the etc/hostlist # It is run by the NOVA nagios and can alarm based on thresholds passed in as args # Nagios return codes:
# 2 = Critical Event, 1 = Warning Event, 0 = OK Event, 3 = Unknown Event ###########################################################################################
print_usage() {
	/bin/echo "USAGE: $0 -w warn -c crit -n name_of_check -s name_of_service [-x regex] [-m minimum] [-g regexStringSearch]"
	/bin/echo "WARN threshold should be lower than CRITICAL"
    /bin/echo "name_of_check must be either TOTAL or ERRORS"
	/bin/echo "threshold Y or N indicates if process alert logic"
    /bin/echo "minimum is a min throughput below which critical alarm will be thrown"
}
#Debug variable 0=Do not Echo messages to the screen 1= Echo messages to the screen
err_code="500"
debug=0
#remember bash's default internal separator so we can restore at the end
OIFS=$IFS
#change bash's internal separator from space/tab/newline to newline only - this helps keep 1 entry per full log line
IFS=$'\n'

#Addng the PATH to local scripts
export NOVA_HOME=/opt/ea/nova
export PATH=$PATH:$NOVA_HOME/bin

#Variables used to send data to graphite/carbon
RootPath="Opsview.GOP-GPO_Nucleus."
HostnameMod=$(hostname | sed 's/\./_/g')
CarbonHost="esmnagwest04.ea.com"
CarbonPort=2003

#Generate a file with the last five minutes to be used as cache
get_cached_file(){

   #echo 'Searching for:'$searchRegex':'
   cache_5min_lock=cache_5min.lock 
   cache_5min_logfile=cache_5min.log 

   #If file was generated more than 2 minutes ago then regenerate
   #echo $httpLogRoot
   too_old=$(find $httpLogRoot -type f -iname $cache_5min_logfile -mmin -2 -print | wc -l)
   # too_old=1
      if [[ $debug -eq 1 ]] ; then
         echo "Too old "$too_old
      fi
   #Trying to avoid access while generating new cache file
   if [[ $too_old -eq 0 ]]; then
     if [[ ! -f $httpLogRoot/$cache_5min_lock ]]; then
           if [[ $debug -eq 1 ]] ; then 
             echo "Generating new cache file"
           fi
           touch $httpLogRoot/$cache_5min_lock
	   output=$(find $httpLogRoot -type f -iname "*$httpLogName*" -not -name "*.gz" -mmin -5  -exec nice -n 19 grep -E "($searchTime)" {} \;   > $httpLogRoot/$cache_5min_logfile)
	   rm $httpLogRoot/$cache_5min_lock
     else
        while [ -f $httpLogRoot/$cache_5min_lock]
        do	 
           sleep 1
	done	
     fi
   fi
}


while getopts w:c: option; do
  case ${option} in
	w) warn=$OPTARG
	   ;;
	c) crit=$OPTARG
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


if [[ -z $warn ]]; then
        warn="null"
fi
if [[ -z $crit ]]; then
        crit="null"
fi

if [[ ($warn != "null" && $crit != "null") ]]; then
        if [[ $warn -ge $crit ]]; then
        print_usage
        exit 3
        fi
fi

###### Prepare for Collection - set the "last 5 minutes" query term ######### i=0
minToScan=5
for ((minOffset=minToScan; minOffset >= 1; minOffset--)) do
    dateStamps[i]="$(date --date "$(date --date "$dte $minOffset min ago")" +'%m/%d/%y %H:%M|')"
    let "i += 1"
    searchString=$searchString"$(date --date "$(date --date "$dte $minOffset min ago")" +'%m/%d/%y %H:%M|')"
done
searchString=${searchString%|}
searchTime=$searchString

if [[ debug -eq 1 ]] ; then 
   echo "searchTIme  " $searchTime
fi
#The following is a default location for all servers of all clusters and all purposes
NOVA_HOME=/opt/ea/nova
#A file containing specific behavious for a specific kind of servers
PROP_FILE=GOPTxnCOunt.prop

if [[ -f $NOVA_HOME/$PROP_FILE ]] ; then
   . $NOVA_HOME/$PROP_FILE
else
#  default to nucleus standard httpd logname and location #  but check for clusters with non-standard locations httpLogRoot="/opt/ea/nova/nucleus/"
   httpLogRoot="/opt/ea/nova/nucleus/"
   httpLogName="httpd_access.log"
fi



#Try to generate 5 minute cache file and avoid concurrent access when generating the file 
get_cached_file 

#Search for the case
#Set the timestamp for the graphs
v_date=$(date +%s)

output=( $( cat $httpLogRoot/$cache_5min_logfile | xgame | tail -n+6 | 
  awk -v RootPath="$RootPath"  -v v_date="$v_date" -v HostnameMod="$HostnameMod" '
       { req[$3] = $3; count[$3] = $1/5; percent[$3] = $2 }
       END {
              for (r in req) { 
                   v_req = req[r];
                   if (req[r] == "")
                        v_req = "Unknown"
                   split(percent[r],s_perc,"%");
                   print RootPath HostnameMod ".TPM5." v_req ".overallTPM "  count[r] " " v_date ;
                   print RootPath HostnameMod ".TPM5." v_req ".overallTPMPercentage "  s_perc[1] " " v_date 
                   total++ 
                } 
                print total  # Setting the number of lines returned from xgame
           } ' |sort -n 
) )

#In the last position of the array setting the number of lines returned from xgame
# if this  number is greater than 250.. Do not send to carbon... exit
num_lines=$(echo ${#output[@]}-1| bc) 
if [[ $num_lines -gt 250 ]] ; then
   echo "Unexpected number of lines"
   exit 3
fi

message=""
for item in ${output[*]}
do
 message=$message$item"\n"
 if [[ debug -eq 1 ]] ; then
    echo $item
 fi
done
#echo $message
echo $message >> $httpLogRoot/graphite_history.log
echo -e $message | nc $CarbonHost $CarbonPort  # This inserts the date into dev graphite

exit 0

