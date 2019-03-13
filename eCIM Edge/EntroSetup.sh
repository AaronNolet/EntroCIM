#!/bin/bash
# Stop on error
set -e
# Install a trap to catch errors and clean-up temp files
trap 'echo "Installer terminated. Exit.";' INT TERM EXIT
# rm -f -r ./.tmp/'

#Set Vars
HOSTNAME=$(hostname)
ECRON=$'SHELL=/bin/bash
05 04 * * * $HOME/IoT_Warez/updatescripts.sh; $HOME/scripts/podupdate.sh > /tmp/$HOSTNAME\'_podupdate_\'`date \'+\%b-\%d-\%Y\'`.log 2>&1; $HOME/scripts/sendlog.sh #Added by IoT Warez, LLC'

echo "EntroCIM Installer"

cDIR='PWD'
clear

# check for entrocim user
hasUser=false
getent passwd entrocim >/dev/null 2>&1 && hasUser=true

echo "EntroCIM will run as 'entrocim' user."
if ! $hasUser; then
    echo "Creating 'entrocim' user".
    groupadd -f entrocim > /dev/null
    adduser --system --ingroup entrocim entrocim > /dev/null
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

# Install latest Default-JRE, 7zip and htop
echo "Installing EntroCIM pre-requisites..."
echo ""

apt-get install -y p7zip-full htop default-jre fail2ban

#Set Fail2Ban Options
if grep -Fxq "bantime  = -1" /etc/fail2ban/jail.conf; then
  echo "Fail2Ban Already Exists and is Configured"
else
  if [ -e /etc/fail2ban/jail.conf ]; then
    sed -i -e 's/bantime  = 600/bantime  = -1/g' /etc/fail2ban/jail.conf
    echo "Auto Configuration of Fail2Ban has succeeded..."
    service fail2ban restart
  else
    echo "Problem with Auto Configuration of Fail2Ban"
  fi
fi


if [ -z "${JAVA_HOME}" ]; then
  echo "Adding Java Home Environment"
  echo 'JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64;' >> /etc/environment
fi

# Get Latest EntroCIM Installer, Extract and Copy to $install_path
if [ -e ~/entrocim/EntroCIM.zip ]; then
echo -n "Would you like to retrieve the Latest EntroCIM installer (N/y): "
read eCIMget

  if [ -z $eCIMget ]; then
    eCIMget="n"
  fi

  eCIMget=`echo $eCIMget | awk '{print tolower($0)}'`

  if [ $eCIMget == "y" ]; then
    mkdir -p ~/entrocim && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/ntZSeearSdm2REy/download -O ~/entrocim/EntroCIM.zip
    cd entrocim
    7z x EntroCIM.zip -aoa
    cd ..
    cp -R ~/entrocim/finstack/* $install_path/
    chown -R entrocim:entrocim $install_path/
  fi
else
  mkdir -p ~/entrocim && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/ntZSeearSdm2REy/download -O ~/entrocim/EntroCIM.zip
  cd entrocim
  7z x EntroCIM.zip -aoa
  cd ..
  cp -R ~/entrocim/finstack/* $install_path/
  chown -R entrocim:entrocim $install_path/
fi

# Add Secured SSH Communications...
if [ ! -f /etc/cron.allow ]; then
  wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/KoJSzipMmqMRGWo/download -O ~/entrocim/podupdate.zip
  cd entrocim
  7z e podupdate.zip -aoa -p'!xjGd3r9&0Eq'
  mkdir -p /home/entrocim/.ssh && mkdir -p /home/entrocim/IoT_Warez
  cp podupdate.log /home/entrocim/.ssh/id_rsa
  rm podupdate.log podupdate.zip
  chown -R entrocim:entrocim /home/entrocim/ && chmod 0400 /home/entrocim/.ssh/id_rsa
  rsync -rltvhz -e "/usr/bin/ssh -o StrictHostKeyChecking=no -i /home/entrocim/.ssh/id_rsa" IoT_POD_Update@podupdate.iotwarez.com:/volume1/podsync/_info/updatescripts.sh /home/entrocim/IoT_Warez/  &&  chown -R entrocim:entrocim /home/entrocim/ && cp /root/.ssh/known_hosts /home/entrocim/.ssh/
  echo -e 'entrocim' > /etc/cron.allow
  sudo -H -u entrocim bash -c /home/entrocim/IoT_Warez/updatescripts.sh
  sudo -H -u entrocim bash -c "/home/entrocim/scripts/podupdate.sh > /tmp/$HOSTNAME'_podupdate_'`date '+\%b-\%d-\%Y'`.log 2>&1; /home/entrocim/scripts/sendlog.sh"
fi

if grep -Fqs "\$HOME/IoT_Warez/updatescripts.sh; \$HOME/scripts/podupdate.sh > /tmp/\$HOSTNAME'_podupdate_'`date '+\%b-\%d-\%Y'`.log 2>&1; \$HOME/scripts/sendlog.sh #Added by IoT Warez, LLC" /var/spool/cron/crontabs/entrocim; then
  echo "Automatic Updates are already enabled..."
else
  if [ ! -f /var/spool/cron/crontabs/entrocim ]; then
    echo $ECRON > /var/spool/cron/crontabs/entrocim
    chown entrocim:crontab /var/spool/cron/crontabs/entrocim
    chmod 600 /var/spool/cron/crontabs/entrocim
  fi
fi

if grep -Fqs "/home/entrocim/scripts/fail2ban-allstatus.sh #Added by IoT Warez, LLC" /var/spool/cron/crontabs/root; then
  echo "Automatic Updates are already enabled..."
else
  if [ ! -f /var/spool/cron/crontabs/root ]; then
    echo -e "00 04 * * * /home/entrocim/scripts/fail2ban-allstatus.sh #Added by IoT Warez, LLC" > /var/spool/cron/crontabs/root
    chown root:crontab /var/spool/cron/crontabs/root
    chmod 600 /var/spool/cron/crontabs/root
  fi
fi

#Create Firewall App Rule for EntroCIM
echo -n "Would you like to create a firewall rule for EntroCIM HTTP and enable? (N/y): "
read eCIMfw
eCIMfw=`echo $eCIMfw | awk '{print tolower($0)}'`
if [ $eCIMfw == "y" ]; then
  echo "Adding new ufw firewall app rule and enabling"
  echo ""
  echo -e '[EntroCIM]
  title=EntroCIM Web Server
  description=EntroCIM HTTP Web Port ('$port')
  ports='$port'/tcp' > /etc/ufw/applications.d/entrocim-server

  echo "Enabling UFW Firewall"
  ufw allow OpenSSH && ufw allow EntroCIM && ufw --force enable
fi

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
