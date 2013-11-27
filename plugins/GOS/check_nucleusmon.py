#!/usr/bin/env python
""" 
this tool reads the log file created by nucleusmonitor.py which should be run as a daemon.
This is an early version of this tool to meet the skate launch. it'll be written to be a lot more generic later
"""
import sys
import commands
import time
#time range in seconds to look back for summary log entries
TIME_RANGE = 600
#parse any log files matching this expression
LOGFILE_NAMES = '/var/log/nucleusmonitor.log*'
info_log_entries = commands.getoutput('grep --with-filename INFO ' + LOGFILE_NAMES).split('\n')
log_times = {}

#number of errors we encountered
err_count = 0
#average values of these fields for this interval
time_connect = 0.0
time_total = 0.0
speed_download = 0.0
valid_log_entries_found = False

for line in info_log_entries:
	logtime,values = line.split(':',1)[1].split(',',1)
	values = values.split('|')[1]

	log_times[time.strptime(logtime, "%Y-%m-%d %H:%M:%S")] = values

oldest_time = time.gmtime(time.time() - TIME_RANGE)

for entry in log_times.iterkeys():
	if entry > oldest_time:
		valid_log_entries_found = True
		values = log_times[entry].split(' ')
                time_total += float(values[0].split(':')[1])
                time_connect += float(values[1].split(':')[1])
                speed_download += float(values[2].split(':')[1])
		err_count += int(values[3].split(':')[1])

if valid_log_entries_found:
	print ('Aggregate from the last %d seconds | time_total:%f time_connect:%f speed_download:%f err_count:%d' % ( TIME_RANGE, time_total, time_connect, speed_download, err_count))
else:
	print 'ERR: no aggregate log entries found in the last %d seconds' % TIME_RANGE
