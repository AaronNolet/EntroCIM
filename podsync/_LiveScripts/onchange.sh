#!/bin/bash

# **********************************************
# * Check if EntroCIM, Fin or Sky and Set Vars *
# **********************************************

if systemctl cat skyspark.service > /dev/null 2>&1; then
  FolderMonitor=$(systemctl cat skyspark.service |grep WorkingDirectory=/|sed 's/WorkingDirectory=//')/lib/fan/
  SkyFin=Sky
elif systemctl cat finstack.service > /dev/null 2>&1; then
  FolderMonitor=$(cat /etc/init.d/finstack |grep HomeFolder=/|sed 's/HomeFolder=//')/lib/fan/
  SkyFin=Fin
elif systemctl cat entrocim.service > /dev/null 2>&1; then
  FolderMonitor=$(cat /etc/init.d/entrocim |grep HomeFolder=/|sed 's/HomeFolder=//')/lib/fan/
  SkyFin=eCIM
fi

# ******************************************************
# * Monitor Fan Folder for changes and Restart Service *
# ******************************************************

ls -l $FolderMonitor > /tmp/watchfile

while true; do
sleep 10
ls -l $FolderMonitor > /tmp/watchfile2
diff -q /tmp/watchfile /tmp/watchfile2 > /dev/null
if [ $? -ne 0 ] ; then
  if [ "$SkyFin" == "Fin" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting finstack Service"
    service finstack stop
    sleep 10
    service finstack start
    echo "Completed..."
  elif [ "$SkyFin" == "Sky" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting skyspark Service"
    service skyspark stop
    sleep 10
    service skyspark start
    echo "Completed..."
  elif [ "$SkyFin" == "eCIM" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting EntroCIM Service"
    service entrocim stop
    sleep 10
    service entrocim start
    echo "Completed..."
  fi
fi
cp /tmp/watchfile2 /tmp/watchfile
done
