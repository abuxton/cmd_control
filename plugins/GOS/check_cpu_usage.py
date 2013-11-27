#!/usr/bin/python
#
# Python script to check cpu usage percentage.
#
# date:   05/17/10
# python: V2.3
#
# example call: check_cpu -w75.0 -c80.0
# NOTES: depends on nagios.py module.

import commands
import getopt
import nagios
import re
import sys

DEFAULT_ITERATION_COUNT = 5
DEFAULT_ITERATION_DELAY = 0.01

# Defaults for crit and warn used for initializaiton only.
# Will not be used in calculations.
DEFAULT_CRITICAL = 90.0
DEFAULT_WARNING  = 75.0

STATUS_MESSAGE       = "Cpu at %3.2f%%"
STATUS_AMENDMENT     = ", should be under %3.2f%%"
GET_CPU_IDLE_COMMAND = "/usr/bin/top -b -n%d -d%02.2f | grep 'Cpu(s)'"

PERFORMANCE_MESSAGE  = "Cpu=%3.2f%%;%3.2f;%3.2f"

CPU_IDLE_INDEX = 3

# Caluclates cpu usage using 'top' command.
# Takes average of n iterations, using the Cpu Idle percentage.
# Returns inverse (ie. 100 - idle) of average idle percentage.
def get_cpu_usage(numIterations, iterationDelay):
    usage = -1.0

    info = ""
    # construct system 'top' command
    cmd = GET_CPU_IDLE_COMMAND % (numIterations, iterationDelay)

    status, output = commands.getstatusoutput(cmd)

    if status != 0:
        info = "Failed to execute 'top' command"
    else:    
        # Calculate average of cpu usage
        iterCount = 0
        total = 0.0
        for line in output.split("\n"):
            # Strip unwanted data from line
            # Split into array
            cpus = re.sub("[^0-9,.]+", "", line).split(",")
            if len(cpus) > CPU_IDLE_INDEX:
                cpuIdle = float(cpus[CPU_IDLE_INDEX])
                total += cpuIdle
                iterCount += 1

        if iterCount == numIterations:
            average = (total / numIterations)

            # Cpu usage equals the inverse of the average idle percentage
            usage = 100.0 - average
            info = STATUS_MESSAGE % usage
        else:
            usage = -1.0
            info  = "Failed to parse output from 'top' command" 
        
    return usage, info

# prints out help information
def help_message():
    print """
Uses 'top' command to check cpu usage percentage.
    Calculates cpu usage from top command's cpu idle percentage, by
    taking average of 'n' iterations.

    -w|--warning  : Issue warning message when cpu usage
                    is greater than or equal to provided value.

    -c|--critical : [optional] Issue cricical message when cpu
                    usage is greater than or equal to provided
                    value.

    -n            : [optional] Number of iterations for 'top'
                    command to run, defaults to %d.

    -d            : [optional] Delay (in seconds) between 
                    iterations, defaults to %02.2f.

Examples: check_cpu -w 75.0 -c 90.0
          check_cpu -w 75.0 -c 90.0 -n 10 -d 0.1
""" % (DEFAULT_ITERATION_COUNT, DEFAULT_ITERATION_DELAY)



#----------------------------------MAIN-------------------------------

def main():

    rStatus        = nagios.STATUS_UNK
    warningValue   = DEFAULT_WARNING
    criticalValue  = DEFAULT_CRITICAL
    iterations     = DEFAULT_ITERATION_COUNT
    delay          = DEFAULT_ITERATION_DELAY

    hasWarningValue  = False
    hasCriticalValue = False  # critical value is optional

    # Parse out options
    opts, args = getopt.getopt(sys.argv[1:], "hw:c:d:n:", ["help", "warning=", "critical="])

    for opt, val in opts:
        val = val.replace("=","")
        if opt in ("-h", "--help"):
            help_message()
            sys.exit()
        elif opt in ("-c", "--critical"):
            criticalValue = float(val)
            hasCriticalValue = True
        elif opt in ("-w", "--warning"):
            warningValue =  float(val)
            hasWarningValue = True
        elif opt == "-n":
            iterations = int(val)
        elif opt == "-d":
            delay = float(val)

    # Must have a warning value
    if not hasWarningValue:
        nagios.plugin_exit(rStatus, "No warning value specified", "")

    # Must have a critical value
    if not hasCriticalValue:
        nagios.plugin_exit(rStatus, "No critical value specified", "")

    # Get the cpu usage for the box
    cpuUsage, info = get_cpu_usage(numIterations=iterations, iterationDelay=delay)

    if cpuUsage < 0.0:
        nagios.plugin_exit(rStatus, info, "")

    # Determine status
    rStatus = nagios.STATUS_OK
    performance = PERFORMANCE_MESSAGE % (cpuUsage, warningValue, criticalValue)

    if cpuUsage >= warningValue:
        info += STATUS_AMENDMENT % warningValue
        rStatus = nagios.STATUS_WARN

        if cpuUsage >= criticalValue:
            rStatus = nagios.STATUS_CRIT

    nagios.plugin_exit(rStatus, info, performance)

if __name__ == '__main__':
    main()
