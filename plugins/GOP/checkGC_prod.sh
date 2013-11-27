#!/bin/bash

MYDIR=/opt/ea/nova/scripts
rm -f $MYDIR/wdl_prod*

wget -q -T 30 -t 1 --output-document=$MYDIR/wdl_prod --post-file=$MYDIR/gcrequest_prod https://ps.gcsip.com/wdl/wdl --no-check-certificate 

test=$(sed -n '/Not authorised/p' $MYDIR/wdl_prod)
#test=$(sed -n '/INSERTATTEMPT_MAX_NR_OF_ATTEMPTS_REACHED/p' $MYDIR/wdl_prod)
responseline=$(sed -n '/RESULT/p' $MYDIR/wdl_prod)
if [ -n "$test" ]; then
  echo "GlobalCollect 200 OK: https://ps.gcsip.com/wdl/wdl "
  exit 0
else
  echo "GlobalCollect 500 CRITICAL: expected Not authorised, received  "$responseline
#  echo "invalid response, expected INSERTATTEMPT_MAX_NR_OF_ATTEMPTS_REACHED, received  "$responseline
  exit 2
fi


