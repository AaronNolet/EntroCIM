#!/bin/bash
export https_proxy=https://gwwcfproxy.gwl.bz:8443
export proxy=http://gwwcfproxy.gwl.bz:8080
HOSTNAME=$(hostname)
BACKDEST=https://nextcloud.heptasystems.com:8443/nextcloud/s/ZTsdkpGk3ECgwrX
LATESTSNAP=`ls -rt /apps/finstack/db/londonLife/snapshots/* | tail -1`
BACKFILE=$HOSTNAME-Snapshot.zip
LOGLOC=/data/hepta

echo $LATESTSNAP > $LOGLOC/latestsnap.log

if [ ! -f $LOGLOC/priorsnap.log ]; then
  echo 'No prior snapshots...' > $LOGLOC/priorsnap.log
fi

diff -q $LOGLOC/latestsnap.log $LOGLOC/priorsnap.log > /dev/null
if [ $? -ne 0 ] ; then
  cp $LATESTSNAP $LOGLOC/$BACKFILE
  cd $LOGLOC
  bash ~/cloudsend.sh $BACKFILE $BACKDEST
  cd $PWD
  cat $LOGLOC/latestsnap.log > $LOGLOC/priorsnap.log
fi
