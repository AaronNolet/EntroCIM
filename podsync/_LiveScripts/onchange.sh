#!/bin/bash

# **********************************************
# * Check if EntroCIM, Fin or Sky and Set Vars *
# **********************************************

if systemctl cat skyspark.service > /dev/null 2>&1; then
  FolderMonitor=$(systemctl cat skyspark.service |grep WorkingDirectory=/|sed 's/WorkingDirectory=//')/lib/fan/
  SkyFin=Sky
  PIDname="skyspark.pid"
elif systemctl cat finstack.service > /dev/null 2>&1; then
  FolderMonitor=$(cat /etc/init.d/finstack |grep HomeFolder=/|sed 's/HomeFolder=//')/lib/fan/
  SkyFin=Fin
  PIDname="finstack.pid"
elif systemctl cat entrocim.service > /dev/null 2>&1; then
  FolderMonitor=$(cat /etc/init.d/entrocim |grep HomeFolder=/|sed 's/HomeFolder=//')/lib/fan/
  SkyFin=eCIM
  PIDname="entrocim.pid"
fi

PIDFile="/var/run/$PIDname"

# ******************************************************
# * Monitor Fan Folder for changes and Restart Service *
# ******************************************************

ls -l $FolderMonitor > /tmp/watchfile

while true; do
CurPID=$(cat $PIDFile)
sleep 10
ls -l $FolderMonitor > /tmp/watchfile2
diff -q /tmp/watchfile /tmp/watchfile2 > /dev/null
if [ $? -ne 0 ] ; then
  if [ "$SkyFin" == "Fin" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting finstack Service"
    service finstack stop
    wait $CurPID
    service finstack start
    echo "Completed..."
  elif [ "$SkyFin" == "Sky" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting skyspark Service"
    service skyspark stop
    wait $CurPID
    service skyspark start
    echo "Completed..."
  elif [ "$SkyFin" == "eCIM" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting EntroCIM Service"
    service entrocim stop
    wait $CurPID
    service entrocim start
    echo "Completed..."
  fi
  echo "$PIDFile - $CurPID" > /tmp/PIDlog.log
fi
cp /tmp/watchfile2 /tmp/watchfile
done
