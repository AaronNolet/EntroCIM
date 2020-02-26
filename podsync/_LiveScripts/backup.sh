#!/bin/bash
HOSTNAME=$(hostname)
DATE=`date +%b-%d-%Y`
CHECKDIR="var"
BACKNUM="1"
RHOST=IoT_POD_Update@podupdate.iotwarez.com

shopt -s extglob

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

if [ -f "/tmp/backlist.log" ]; then
  rm /tmp/backlist.log
fi
if [ -f "/tmp/keep.log" ]; then
  rm /tmp/keep.log
fi
if [ -f "/tmp/rsync.log" ]; then
  rm /tmp/rsync.log
fi



if [ -d "$BACKUPSOURCE/$CHECKDIR" ]; then
  for dir in $BACKUPSOURCE/var/proj/*; do
    if [ -d "$dir" ]; then
      if [[ -d "$dir"/backup ]]; then
        BACKFILES=$(ls -rt "$dir"/backup/ | tail -$BACKNUM)
        echo "$dir"/backup/$BACKFILES >> /tmp/backlist.log
        echo $BACKFILES >> /tmp/keep.log
      fi
    fi
  done
else
echo "Error!!!"
fi

if /usr/bin/ssh -i $HOME/.ssh/id_rsa IoT_POD_Update@podupdate.iotwarez.com '[ -d /volume1/podsync/_backups/$HOSTNAME ]'; then
  /usr/bin/rsync -vhz `cat /tmp/backlist.log` --log-file=/tmp/rsync.log "/usr/bin/ssh -i $HOME/.ssh/id_rsa" $RHOST:/volume1/podsync/_backups/$HOSTNAME/
else
  /usr/bin/ssh -i $HOME/.ssh/id_rsa IoT_POD_Update@podupdate.iotwarez.com "mkdir /volume1/podsync/_backups/$HOSTNAME"
  /usr/bin/rsync -vhz `cat /tmp/backlist.log` --log-file=/tmp/rsync.log "/usr/bin/ssh -i $HOME/.ssh/id_rsa" $RHOST:/volume1/podsync/_backups/$HOSTNAME/
fi

echo -e "Backup Last Run: $DATE on $HOSTNAME\n\nVariables:\n\nSkyFin: $SkyFin\nBACKUPSOURCE: $BACKUPSOURCE\nBACKFILE:\n\n$(cat /tmp/keep.log)\n\nRSYNC Log$
cat /tmp/rsync.log >> /tmp/backup-$DATE.log
