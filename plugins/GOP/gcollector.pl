#!/usr/bin/perl 
#Name: gcollector.pl
#Description: Garbage Collector Script
#Developed by: Luis Licon <llicon@ea.com> - May 26th, 2011
#Arguments: None
#Output: GC Timing, Size Before GC, Size After GC and Available Heap Space
###############################################################################

##### Get values #####

$Year=`date +%Y`;
$month=`date +%m`;
$day=`date +%d`;

$hour=`date +%H`;
$Minute=`date +%M`;

chop($Year);
chop($month);
chop($day);

chop($hour);
chop($Minute);
$Minute=1*$Minute;

#File Variables
$wrapperLogPath="/opt/ea/nova/nucleus/serv";
$wrapperLogFile="$wrapperLogPath" . "/" . "wrapper.log.$Year$month$day";

$Window = "[";

if($Minute >= 5){
	for ($i=$Minute-4; $i <= $Minute; $i++){
		if($i <= 10){
			$Window .= "0$i|";
		}else{
			$Window .= "$i|";
		}
	}
}

if($Minute <  5){
	for($i=$Minute; $i>$Minute-5; $i--){
		if($i > 0){
			if($i < 10){
				$Window .= "0$i|";
			}else{
				$Window .= "$i|";
			}
		}else{
			if($i == 0){
				$Window .= "00|";
			}else{
				$j=$i+60;
				$Window .= "$j|";
			}
		}
	}
}
chop($Window);
$Window .= "]";

#get timing readings
@wrapperSec=`cat $wrapperLogFile | grep "$Year/$month/$day\ $hour:$Window.*real" | grep "K->" | grep "K)" | awk -F"|" '{print \$2}' | awk -F"," '{print \$2}' | awk -F"]" '{print \$1}' | sed -e 's/\ secs//g'`;

#get size of live objects before GC takes place
@sizeBeforeGC=`cat $wrapperLogFile | grep "$Year/$month/$day\ $hour:$Window.*real" | grep "K->" | grep "K)"  | awk -F"|" '{print \$2}' | awk -F":" '{print \$2}' | awk -F"," '{print \$1}' | awk -F"K" '{print \$1}' | sed -e 's/\ //g'`;

#get size of live objects after GC takes place
@sizeAfterGC=`cat $wrapperLogFile | grep "$Year/$month/$day\ $hour:$Window.*real" | grep "K->" | grep "K)"  | awk -F"|" '{print \$2}' | awk -F">" '{print \$2}' | awk -F"K" '{print \$1}'`;

#get actual available heap size
$heapAvailable=`cat $wrapperLogFile | grep "$Year/$month/$day\ .*real" | grep "K->" | grep "K(" | tail -n 1 | awk -F"|" '{print \$2}' | awk -F"(" '{print \$2}' | awk -F"K" '{print \$1}'`;
chop($heapAvailable);

#get total heap used after GC takes place
$totalHeapUsedAfterGC=`cat $wrapperLogFile | grep "$Year/$month/$day\ .*real" |  tail -n 1 | awk 'match(\$0,/[0-9]+ secs] [0-9]+K->[0-9]+K\\([0-9]+K/) { print substr(\$0, RSTART, RLENGTH) }' | sed -e 's/(/>/g' | sed -e 's/K//g' | awk -F">" '{print \$2}'`;
chop($totalHeapUsedAfterGC);

#get total heap size
$totalHeapSize=`cat $wrapperLogFile | grep "$Year/$month/$day\ .*real" |  tail -n 1 | awk 'match(\$0,/[0-9]+ secs] [0-9]+K->[0-9]+K\\([0-9]+K/) { print substr(\$0, RSTART, RLENGTH) }' | sed -e 's/K//g' | awk -F"(" '{print \$2}'`;
chop($totalHeapSize);

#Sum of timings
$totalSec=0;
foreach $sec(@wrapperSec){
	$totalSec=$totalSec+$sec;
}

#conversion to miliseconds
$totalTiming=$totalSec*1000;

#Calculating Average of @sizeBeforeBC in the last minute
$totalSizeBGC=0;$contb=0;
foreach $sizeb(@sizeBeforeGC){
	$totalSizeBGC+=$sizeb;
	$contb++;
}

if($contb ne 0 && $contb != NULL){
	$totalSizeBGC/=$contb;
}else{
	$totalSize=0;
}

#Calculating Average of @sizeAfterBC in the last minute
$totalSizeAGC=0;$conta;
foreach $sizeb(@sizeAfterGC){
	$totalSizeAGC+=$sizeb;
	$conta++;
}
if($conta ne 0 && $conta != NULL){
	$totalSizeAGC/=$conta;
}else{
	$totalSizeAGC=0;
}


#printing fresh values
print "Timing:$totalTiming|SizeBeforeGC:$totalSizeBGC|SizeAfterGC:$totalSizeAGC|totalHeapFree:$heapAvailable|totalHeapUsedAfterGC:$totalHeapUsedAfterGC|totalHeapSize:$totalHeapSize";
