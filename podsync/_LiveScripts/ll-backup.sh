#!/bin/bash
HOSTNAME=$(hostname)
BACKDEST=https://nextcloud.heptasystems.com:8443/nextcloud/s/ZTsdkpGk3ECgwrX
LATESTSNAP=`ls -rt /apps/finstack/db/londonLife/snapshots/* | tail -1`
BACKFILE=$HOSTNAME-Snapshot.zip
LOGLOC=/data/hepta
cDIR='PWD'

if [ ! -f $LOGLOC/$BACKFILE ]; then
  cp $LATESTSNAP $LOGLOC/$BACKFILE
fi

echo $LATESTSNAP > $LOGLOC/latestsnap.log

if [ ! -f $LOGLOC/priorsnap.log ]; then
  echo 'No prior snapshots...' > $LOGLOC/priorsnap.log
fi

diff -q $LOGLOC/latestsnap.log $LOGLOC/priorsnap.log > /dev/null
if [ $? -ne 0 ] ; then
  bash $cDIR/cloudsend.sh $LOGLOC/$BACKFILE $BACKDEST
  cat $LOGLOC/latestsnap.log > $LOGLOC/priorsnap.log
fi
