#!/bin/ksh
#######################################################################
# Script counts number of processes running 
# Nagios Exit Codes: 
# 2=Critical/Major Event 1=Warning Event 0=Clear Event 3=Unknown Event
#######################################################################
print_usage() {
	/bin/echo "USAGE: $0 -w value,above|below -c value,above|below -e err_code -p proc" 
}
while getopts w:c:e:p:h options; do
	case ${options} in
	w) warn=$OPTARG;;
        c) crit=$OPTARG;;
        e) err_code=$OPTARG;;
	p) proc=${OPTARG};;
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
if [[ $warn != "null" ]]; then
	w_val=`echo $warn | awk -F, '{print $1}'`
	w_oper=`echo $warn | awk -F, '{print $2}'`
fi
if [[ $crit != "null" ]]; then
	c_val=`echo $crit | awk -F, '{print $1}'`
	c_oper=`echo $crit | awk -F, '{print $2}'`
fi
####### Get values #######
pcount=`ps auxgwww | grep "$proc" | grep -v grep | grep -v check | wc -l` 
pcount=`echo $pcount | sed 's/ //'`

if [[ $pcount != +([0-9]) ]]; then
print "Unknown error ::$err_code::critical=$crit warning=$warn:: Evaluvated output of command 'ps' is not numeric. Can not proceed further"
exit 3;
fi

cpu_mem=`ps aux | grep "$proc" |grep -v grep | awk '{CPU += $3} {MEM += $4} {print CPU " " MEM}' | tail -1`
cpu=`echo $cpu_mem | awk '{print $1}'`
mem=`echo $cpu_mem | awk '{print $2}'`
####### Optional return results ########
if [[ $crit != "null" && $c_oper = "above" ]]; then
	if [[ $pcount -gt $c_val ]]; then
		/bin/echo "Process Count CRITICAL::$err_code::warn=$warn,critical=$crit::process=$proc,count=$pcount | count=$pcount cpu=$cpu mem=$mem"
		exit 2
	fi
elif [[ $crit != "null" && $c_oper = "below" ]]; then
	if [[ $pcount -lt $c_val ]]; then
		/bin/echo "Process Count CRITICAL::$err_code::warn=$warn,critical=$crit::process=$proc,count=$pcount | count=$pcount cpu=$cpu mem=$mem"
	        exit 2
        fi
fi
if [[ $warn != "null" && $w_oper = "above" ]]; then
	if [[ $pcount -gt $w_val ]]; then
		/bin/echo "Process Count WARNING::$err_code::warn=$warn,critical=$crit::process=$proc,count=$pcount | count=$pcount cpu=$cpu mem=$mem"
		exit 1
	fi
elif [[ $warn != "null" && $w_oper = "below" ]]; then
	if [[ $pcount -lt $w_val ]]; then
		/bin/echo "Process Count WARNING::$err_code::warn=$warn,critical=$crit::process=$proc,count=$pcount | count=$pcount cpu=$cpu mem=$mem"
                exit 1
	fi
fi
/bin/echo "Process OK::$err_code::warn=$warn,critical=$crit::process=$proc,count=$pcount | count=$pcount cpu=$cpu mem=$mem"
exit 0
