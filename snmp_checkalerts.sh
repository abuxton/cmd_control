#!/bin/bash

CACHE='/home/monitor/.cache/alerts'

if [ ! -f ${CACHE} ]
then
        echo "ERROR:FILE NOT FOUND ${CACHE}"
        exit 1
fi

#echo
echo "TIMESTAMP=`stat -c "%Y" $CACHE`"
cat $CACHE

exit 0
