#!/usr/bin/python
#
# This file contains definitions used for writing Nagios plugin in Python.
#
# Author: Javier Cubero
# Python version: 2.3
# Date: April 10, 2009

import sys

STATUS_OK = 0
STATUS_WARN = 1
STATUS_CRIT = 2
STATUS_UNK = 3

statusText = ['OK','WARNING','CRITICAL', 'UNKNOWN']

def plugin_exit(status,info,prof):
        print '%s: %s|%s' % (statusText[status],info,prof)
        sys.exit(status)
