#!/bin/bash
HOSTNAME=$(hostname)
DATE=`date +%b-%d-%Y`
CHECKDIR="var"

# **********************************************
# * Check if EntroCIM, Fin or Sky and Set Vars *
# **********************************************

if systemctl cat skyspark.service > /dev/null 2>&1; then
  BACKUPSOURCE=$(systemctl cat skyspark.service |grep WorkingDirectory=/|sed 's/WorkingDirectory=//')
  SkyFin=Sky
elif systemctl cat finstack.service > /dev/null 2>&1; then
  BACKUPSOURCE=$(cat /etc/init.d/finstack |grep HomeFolder=/|sed 's/HomeFolder=//')
  SkyFin=Fin
elif systemctl cat entrocim.service > /dev/null 2>&1; then
  BACKUPSOURCE=$(cat /etc/init.d/entrocim |grep HomeFolder=/|sed 's/HomeFolder=//')
  SkyFin=eCIM
fi

if [ -d "$BACKUPSOURCE/$CHECKDIR" ]; then
  # Control will enter here if $DIRECTORY exists.
  BACKFILE=`ls -rt $BACKUPSOURCE/var/proj/*/backup/* | tail -1`
else
  BACKFILE=`ls -rt $BACKUPSOURCE/db/*/snapshots/* | tail -1`
fi

if /usr/bin/ssh -i $HOME/.ssh/id_rsa IoT_POD_Update@podupdate.iotwarez.com '[ -d /volume1/podsync/_backups/$HOSTNAME ]'; then
  /usr/bin/rsync -vh $BACKFILE -e --delete-after --log-file=/tmp/rsync.log "/usr/bin/ssh -i $HOME/.ssh/id_rsa" IoT_POD_Update@podupdate.iotwarez.com:/volume1/podsync/_backups/$HOSTNAME/
else
  /usr/bin/ssh -i $HOME/.ssh/id_rsa IoT_POD_Update@podupdate.iotwarez.com "mkdir /volume1/podsync/_backups/$HOSTNAME"
  /usr/bin/rsync -vh $BACKFILE -e --delete-after --log-file=/tmp/rsync.log "/usr/bin/ssh -i $HOME/.ssh/id_rsa" IoT_POD_Update@podupdate.iotwarez.com:/volume1/podsync/_backups/$HOSTNAME/
fi

echo -e "Backup Last Run: $DATE on $HOSTNAME\n\nVariables:\n\nSkyFin: $SkyFin\nBACKUPSOURCE: $BACKSOURCE\nBACKFILE: $BACKFILE\n\nRSYNC Log:\n" > /tmp/backup-$DATE.log
cat /tmp/rsyn.log >> /tmp/backup-$DATE.log

#/usr/bin/ssh -i $HOME/.ssh/id_rsa IoT_POD_Update@podupdate.iotwarez.com "sudo rm /volume1/podsync/_backups/$HOSTNAME/*"

#/usr/bin/rsync -vh $BACKFILE -e "/usr/bin/ssh -i $HOME/.ssh/id_rsa" IoT_POD_Update@podupdate.iotwarez.com:/volume1/podsync/_backups/$HOSTNAME/
