#!/bin/ksh
######################################################################
# This script checks for Oracle 10gRAC +ASM disk space # Nagios return codes: 2=Critical 1=Warning 0=OK 3=Unknown ######################################################################
cmddef='/opt/oracle/product/10gR2/db/bin/asmcmd '
orahomedef='/opt/oracle/product/10gR2/db'
print_usage() {
        echo "This script checks for +ASM disk space"
        echo "USAGE: $0 -w warn -c crit -e error_code -p partition -s sid -o oraclehome -C command"
}
while getopts w:c:e:p:s:o:C:h opt; do
        case ${opt} in
        w) warn=$OPTARG;;
        c) crit=$OPTARG;;
        e) err_code=$OPTARG;;
        p) partition=$OPTARG;;
        s) sid=$OPTARG;;
        o) orahome=$OPTARG;;
        C) comm=$OPTARG;;
        h) print_usage; exit 0;;
        \?) print_usage; exit 0;;
        esac
done
if [[ -z $partition ]]; then
# /bin/echo "Partition Name not specified"
echo "USAGE: $0 -w warn -c crit -e error_code -p partition -s sid"
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
if [[ ($warn != "null" && $crit != "null") ]]; then
        if [[ $warn -le $crit ]]; then
        /bin/echo "WARN threshold should be higher than CRITICAL"
        exit 3
        fi
fi
if [[ -z $orahome ]]; then
	orahome=$orahomedef	
fi
if [[ -z $comm ]]; then
	comm=$cmddef
fi
###### Get values ######
export ORACLE_HOME=$orahome
#export ORACLE_SID=+ASM1
#export ORACLE_SID=$sid
export ORACLE_SID="+"$sid
res=`sudo -u oracle $comm lsdg | grep $partition | awk '{print  $8" "$9" "($9/$8)*100" "(100-(($9/$8)*100))}'` #echo "$res"
#res=`sudo -u oracle $comm lsdg 2> /dev/null| grep $partition | awk '{print  $8" "$9" "($9/$8)*100" "(100-(($9/$8)*100))}'` #echo "$res"
total=`echo $res | awk '{print $1}'`
free=`echo $res | awk '{print $2}'`
free_p=`echo $res | awk '{print $3}'`
used_p=`echo $res | awk '{print $4}'`
free_p=$(printf %.0f $free_p)
used_p=$(printf %.0f $used_p)


if [[ ($total -eq "" || $free -eq "") ]]; then

        echo "BROKEN MONITOR::ESM00016::::partition $partition not found or could not run asmcmd"

        exit 2

fi


###### Optional return results #######

if [[ ($crit -ne "null" && $free_p -le $crit) ]]; then
        echo "+ASM disk space CRITICAL::$err_code::warn=$warn,critical=$crit::partition=$partition,Free%=$free_p%,free=$free,total=$total | "$partition"_free=$free_p,total=$total"
        exit 2
elif [[ ($warn -ne "null" && $free_p -le $warn) ]]; then
        echo "+ASM disk space WARNING::$err_code::warn=$warn,critical=$crit::partition=$partition,Free%=$free_p%,free=$free,total=$total | "$partition"_free=$free_p,total=$total"
        exit 1
elif [[ ($warn -ne "null" && $free_p -ge $warn ) ]]; then
        echo "+ASM disk space OK::$err_code::warn=$warn,critical=$crit::partition=$partition,Free%=$free_p%,free=$free,total=$total | "$partition"_free=$free_p,total=$total"
        exit 0
elif [[ ($warn -eq "null" && $free_p -ge $crit ) ]]; then
        echo "+ASM disk space OK::$err_code::warn=$warn,critical=$crit::partition=$partition,Free%=$free_p%,free=$free,total=$total | "$partition"_free=$free_p,total=$total"
        exit 0
fi
#exit 3
if [[($res == "")]];then
echo "+ASM disk partition not found CRITICAL::$err_code::warn=$warn,critical=$crit::partition=$partition,Free%=$free_p%,free=$free,total=$total | "$partition"_free=$free_p,total=$total"
        exit 2
fi
if [[($crit -eq "null") && ($warn -eq "null")]];then
        echo "none::$err_code::::partition=$partition,Free%=$free_p%,free=$free,total=$total | "$partition"_free=$free_p,total=$total"
        exit 0
fi
