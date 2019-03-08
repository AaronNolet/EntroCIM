#!/bin/bash
HOSTNAME=$(hostname)
BACKDEST=https://nextcloud.heptasystems.com:8443/nextcloud/s/ZTsdkpGk3ECgwrX
LATESTSNAP=`ls -rt /apps/finstack/db/*/snapshots/* | tail -1`
BACKFILE=$HOSTNAME-Snapshot.zip
LOGLOC=/data/hepta

if [ ! -f $LOGLOC/$BACKFILE ]; then
  cp $LATESTSNAP $LOGLOC/$BACKFILE
fi

echo $LATESTSNAP > $LOGLOC/latestsnap.log

if [ ! -f $LOGLOC/priorsnap.log]; then
  cat $LOGLOC/latestsnap.log > $LOGLOC/priorsnap.log
fi

diff -q $LOGLOC/latestsnap.log $LOGLOC/priorsnap.log > /dev/null
if [ $? -ne 0 ] ; then
  ~/cloudsend.sh $LOGLOC/$BACKFILE $BACKDEST
  cat $LOGLOC/latestsnap.log > $LOGLOC/priorsnap.log
fi
