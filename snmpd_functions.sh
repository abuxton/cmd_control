#!/bin/bash
#
# pf_snmpfunctions.sh - simple callable functions for snmpd.conf
# 2011 Karsten McMinn

# values
hpsocket="/var/run/haproxy"
hppid=`pidof -s haproxy`

# functions

function check_secondsbehind() {
  if [ -f "/usr/bin/mysql" ]; then
    r=`mysql -e 'show slave status\G' | grep -i seconds_behind_master | awk '{print $2}'`
    if [[ $r =~ ^[0-9]+$ ]]; then
       echo $r
    elif [[ $r =~ [a-zA-Z]+ ]]; then
       echo "9999"
    elif [[ $(uname -n) =~ [a-zA-Z]+[0-9]+m ]]; then
       echo "0"
    else
       echo "9999"
    fi
  else
    echo "20"; # a warning
  fi
}

function check_pps() {
  rpps1=`netstat --interfaces=eth0|awk 'END { print $4 };'`
  wpps1=`netstat --interfaces=eth0|awk 'END { print $8 };'`
  sleep 1
  rpps2=`netstat --interfaces=eth0|awk 'END { print $4 };'`
  wpps2=`netstat --interfaces=eth0|awk 'END { print $8 };'`
  let rpps=$rpps2-$rpps1
  let wpps=$wpps2-$wpps1
  let pps=$rpps+$wpps
  echo $pps
}

function check_haproxycpu() {
  echo $(ps -p ${hppid} -o %cpu|tail -1)
}

function check_haproxytasks() {
  tasks=`echo "show info" | socat ${hpsocket} stdio | awk 'NR==17 { print $2 };'`
  if [ ${tasks} == "" ]; then
    tasks=`echo "show info" | socat ${hpsocket} stdio | awk 'NR==17 { print $2 };'`
  fi
  echo $tasks
}

function check_haproxyconns() {
  cons=`echo "show info" | socat ${hpsocket} stdio | awk 'NR==14 { print $2 };'`
  if [ ${cons} == "" ]; then
    cons=`echo "show info" | socat ${hpsocket} stdio | awk 'NR==14 { print $2 };'`
  fi
  echo $cons
}

function check_haproxyqueue() {
  qlen=`echo "show info" | socat ${hpsocket} stdio | awk 'NR==18 { print $2 };'`
  if [ ${qlen} = "" ]; then
    qlen=`echo "show info" | socat ${hpsocket} stdio | awk 'NR==18 { print $2 };'`
  fi
  echo $qlen

}

function check_haproxymem() {
  echo $(ps -p ${hppid} -o vsz|tail -1)
}

function check_haproxy_ssl_percentage() {
  ssl_connection_count=`echo "show sess" | socat ${hpsocket} stdio | grep ssl | wc -l`
  total_connection_count=`echo "show sess" | socat ${hpsocket} stdio | grep jetty | wc -l`
  percentage_ssl=`/bin/echo -e "scale = 5\n (${ssl_connection_count} / ${total_connection_count}) * 100" | bc`
  echo $percentage_ssl
}

# check for a input, die silently if none
if [ -e $1 ]; then
    exit 1
else
    function=$1
fi

# execute
${function}
exit 0

