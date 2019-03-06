#!/bin/bash
HOSTNAME=$(hostname)
#DATE=`date +%b-%d-%Y`
BACKFILE=`ls -rt /opt/finstack/db/*/snapshots/* | tail -1`
#LATESTFILE=`ls -rt /opt/finstack/db/*/snapshots/ | tail -1`
#/usr/bin/ssh -i $HOME/.ssh/id_rsa IoT_POD_Update@podupdate.iotwarez.com "sudo rm /volume1/podsync/_backups/$HOSTNAME/*"
/usr/bin/rsync -vh $BACKFILE -e "/usr/bin/ssh -i $HOME/.ssh/id_rsa" IoT_POD_Update@podupdate.iotwarez.com:/volume1/podsync/_backups/$HOSTNAME/
