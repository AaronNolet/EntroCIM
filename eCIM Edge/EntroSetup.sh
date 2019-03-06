#!/bin/bash
# Stop on error
set -e
# Install a trap to catch errors and clean-up temp files
trap 'echo "Installer terminated. Exit.";' INT TERM EXIT
# rm -f -r ./.tmp/'
echo "EntroCIM Installer"

cDIR='PWD'

# check for entrocim user
hasUser=false
getent passwd entrocim >/dev/null 2>&1 && hasUser=true

echo "EntroCIM will run as 'entrocim' user."
if ! $hasUser; then
    echo "Creating 'entrocim' user".
    groupadd -f entrocim > /dev/null
    adduser --system --no-create-home --ingroup entrocim entrocim > /dev/null
fi

echo -n "Enter location for EntroCIM (/opt/entrocim): "
read install_path

if [ -z "$install_path" ] || [ "$install_path" == "/" ]; then
    install_path="/opt/entrocim"
fi
if [ ! -d "$install_path" ]; then
  echo "Creating Install Path"
  mkdir $install_path
fi

chown -R entrocim:entrocim "$install_path/"

echo -n "Enter port EntroCIM runs on (8085): "
read port

if [ -z $port ]; then
    port="8085"
fi

echo -n "Enter Java Heap Max Size for EntroCIM Service (512M): "
read heapmax

if [ -z $heapmax ]; then
    heapmax="512M"
fi

# Install latest Default-JRE
apt-get install default-jre -y
if [ -z "${JAVA_HOME}" ]; then
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64;
fi

# Get Latest EntroCIM Installer, Extract and Copy to $install_path
apt-get install unzip htop && mkdir -p ~/entrocim && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/ntZSeearSdm2REy/download -O ~/entrocim/EntroCIM.zip
cd entrocim
unzip EntroCIM.zip
cd ..
cp -R ~/entrocim/finstack/* $install_path/
chown -R entrocim:entrocim $install_path/

#Create Firewall App Rule for EntroCIM
echo -e '[EntroCIM]
title=EntroCIM Web Server
description=EntroCIM HTTP Web Port ('$port')
ports='$port'/tcp' > /etc/ufw/applications.d/entrocim-server

ufw allow OpenSSH && ufw allow EntroCIM && ufw --force enable

echo -e "#!/bin/bash\nsudo -u entrocim java -cp ../lib/java/sys.jar -Dfan.home=../ fanx.tools.Fan proj -port $port  >> ../entrocim.log 2>&1 &" > $install_path/bin/start.sh
chmod +x $install_path/bin/start.sh

echo -n "Automatically run EntroCIM at startup (N/y): "
read auto_start
auto_start=`echo $auto_start | awk '{print tolower($0)}'`

if [ $auto_start == "y" ]; then
echo '#!/bin/sh
### BEGIN INIT INFO
# Provides:          entrocim
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO
# /etc/init.d/entrocim

# File Open MAX Service Fix - Added by IoT Warez, LLC
ulimit -Hn 200000
ulimit -Sn 200000

# set maximum memory allocated for EntroCIM
HeapSize="'$heapmax'"
# set the HTTP port EntroCIM listen on
PortNumber="'$port'"
# set the EntroCIM home folder
HomeFolder='$install_path'

JRE="java -Xmx$HeapSize"
StartCMD="sudo -u entrocim $JRE -cp $HomeFolder/lib/java/sys.jar -Dfan.home=$HomeFolder fanx.tools.Fan proj -httpPort $PortNumber"

PIDFile="/var/run/entrocim.pid"
LogFile="/var/log/entrocim.log"
# Touch the lock file
touch $PIDFile

# Determine user command
case "$1" in
  start)
    echo "Starting EntroCIM"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       $StartCMD >> $LogFile 2>&1 &
       echo $! > /var/run/entrocim.pid
       exit 0
    else
       echo EntroCIM runs with pid: $CurPID
       echo type "/etc/init.d/entrocim stop" to stop it first.
       exit 1
    fi
    ;;
  stop)
    echo "Stopping EntroCIM"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       echo EntroCIM is already stopped.
    else
      kill $CurPID
      rm $PIDFile
    fi
    ;;
  restart)
    echo "Restarting EntroCIM"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       $StartCMD >> $LogFile 2>&1 &
       echo $! > /var/run/entrocim.pid
       echo EntroCIM is restarted.
       exit 0
    else
      kill $CurPID
      rm $PIDFile
      $StartCMD >> $LogFile 2>&1 &
      echo $! > /var/run/entrocim.pid
      echo EntroCIM is restarted.
      exit 0
    fi
    ;;
  status)
    echo "EntroCIM"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       echo is stopped.
       exit 3
    else
      echo is running.
      exit 0
    fi
    ;;
  *)
    echo "Usage: /etc/init.d/entrocim {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0' > /etc/init.d/entrocim
chmod 755 /etc/init.d/entrocim

# bind the service
if [ -f "/usr/sbin/update-rc.d" ]; then
    update-rc.d entrocim defaults > /dev/null
else
    chkconfig --add entrocim > /dev/null
fi

echo '/var/log/entrocim.log {
su root root
minsize 10M
weekly
rotate 12
compress
delaycompress
copytruncate
postrotate
    touch /var/log/entrocim.log
endscript
}' > /etc/logrotate.d/entrocim

# start the service
/etc/init.d/entrocim restart
fi

exit 0
