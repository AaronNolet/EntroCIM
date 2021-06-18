#!/bin/bash
# Stop on error
set -x
# Install a trap to catch errors and clean-up temp files
trap 'echo "Installer terminated. Exit.";' INT TERM EXIT
# rm -f -r ./.tmp/'

if (( $EUID != 0 )); then
    echo "$(tput setaf 1)Please run as root$(tput sgr 0)"
    exit
fi

#Set Vars
HOSTNAME=$(hostname)
#EntroCIM NXTLINK Versions:
# 5.0.7.3740_FoS "djkDr5xxrqAPaES"
# 5.0.5.3161_FoS "apagktAQg3CpWje"
NXTLINK="djkDr5xxrqAPaES"

# FOG Code during install needs to match with case start of file followed by _DCLinuxAgent.zip
NXTFOGLINK="3oiWJeBwtQFbHXM"
extract_folder="EntroCIM"

clear

echo "**********************************"
echo "***     EntroCIM Installer     ***"
echo "**********************************"
echo ""

cDIR='PWD'
GETFWZONE=$(firewall-cmd --get-default-zone)

echo "Currently Ative Firewall Zone: $GETFWZONE"
echo ""

# check for entrocim user
hasUser=false
getent passwd entrocim >/dev/null 2>&1 && hasUser=true

echo "EntroCIM will run as 'entrocim' user."
if ! $hasUser; then
    echo "Creating 'entrocim' user"
    echo ""
    groupadd -f entrocim > /dev/null
    adduser --create-home --system --gid entrocim entrocim > /dev/null
fi

echo -n "Enter location for EntroCIM (/opt/entrocim): "
read install_path

if [ -z "$install_path" ] || [ "$install_path" == "/" ]; then
    install_path="/opt/entrocim"
fi
if [ ! -d "$install_path" ]; then
  echo "Creating Install Path"
  mkdir $install_path
  echo ""
fi

chown -R entrocim:entrocim "$install_path/"

echo -n "Enter port EntroCIM runs on (8080): "
read port
echo ""

if [ -z $port ]; then
    port="8080"
fi

echo -n "Enter Java Heap Max Size for EntroCIM Service (512M): "
read heapmax
echo ""

if [ -z $heapmax ]; then
  heapmax="512M"
fi

#Add SSH Public Key for User Account
echo "Please Supply / Paste the Public SSH Key (if applicable): "
read pkey

if [ "$pkey" ]; then
  echo -n "Please Supply the Username that will be Used with the SSH Key: "
  read pkeyuser
  if [ $pkeyuser ]; then
    echo "Adding Public Key to Administration User..."
    echo ""
    mkdir -p /home/$pkeyuser/.ssh
    echo "$pkey" >> /home/$pkeyuser/.ssh/authorized_keys
    chown -R $pkeyuser:$pkeyuser /home/$pkeyuser/ && chmod 0400 /home/$pkeyuser/.ssh/authorized_keys
  fi
fi

echo -n "Please Supply your EntroCIM FOG Enablement Customer Code (if applicable): "
read custcode
echo ""

if [ -z $custcode ]; then
  fogenabled="n"
else
  fogenabled="y"
fi

echo -n "Would you like to create a firewall rule for EntroCIM HTTP and enable? (N/y): "
read eCIMfw
echo ""

if [ -z $eCIMfw ]; then
  eCIMfw="n"
fi

echo -n "Automatically run EntroCIM at startup (N/y): "
read auto_start
echo ""

if [ -z $auto_start ]; then
  auto_start="n"
fi

# Install latest Default-JRE, 7zip and htop
echo "Installing EntroCIM pre-requisites..."
echo ""

wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y epel-release-latest-8.noarch.rpm -q
yum update -y -q
yum install -y p7zip.x86_64 p7zip-plugins.x86_64 fail2ban java-11-openjdk.x86_64 htop.x86_64 -q

#Set Java environment var
if [ -z "${JAVA_HOME}" ]; then
  echo "Adding Java Home Environment"
  echo ""
  echo "JAVA_HOME=/usr/lib/jvm/jre-11-openjdk;" >> /etc/environment
fi

#Set FOG environment var
if [ $fogenabled == "y" ] && [ -z "${CUST_CODE}" ]; then
  echo "Adding EntroCIM FOG Environment"
  echo ""
  echo "CUST_CODE=$custcode" >> /etc/environment
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
    mkdir -p $PWD/entrocim && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/$NXTLINK/download -O $PWD/entrocim/EntroCIM.zip
    cd entrocim
    7z x EntroCIM.zip -aoa
    cd ..
    cp -R $PWD/entrocim/$extract_folder/* $install_path/
    chown -R entrocim:entrocim $install_path/
  fi
else
  mkdir -p $PWD/entrocim && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/$NXTLINK/download -O $PWD/entrocim/EntroCIM.zip
  cd entrocim
  7z x EntroCIM.zip -aoa
  cd ..
  cp -R $PWD/entrocim/$extract_folder/* $install_path/
  chown -R entrocim:entrocim $install_path/
fi

if [ $fogenabled == "y" ]; then
  mkdir -p $PWD/entrocim && wget "https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/"$NXTFOGLINK"/download?path=%2F&files="$custcode"_DCLinuxAgent".zip -O $PWD/entrocim/$custcode"_DCLinuxAgent".zip
  cd entrocim
  7z x $custcode"_DCLinuxAgent".zip -aoa
  chmod +x DesktopCentral_LinuxAgent.bin
  ./DesktopCentral_LinuxAgent.bin
  cd ..
fi

# Add Secured SSH Communications...
if [ ! -f /etc/cron.allow ]; then
  gp=$(wget -qU "Wget/IoTWarez" -O- https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/j4MeHsQ3PMP4bMo/download)
  wget -qU "Wget/IoTWarez" https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/CqPQXFyFBtM2Zgd/download -O $PWD/entrocim/podupdate.zip
  cd $PWD/entrocim/
  7z e podupdate.zip -aoa -p$gp
  mkdir -p /home/entrocim/.ssh && mkdir -p /home/entrocim/IoT_Warez
  cp podupdate.log /home/entrocim/.ssh/id_rsa
  rm podupdate.log podupdate.zip
  chown -R entrocim:entrocim /home/entrocim/ && chmod 0400 /home/entrocim/.ssh/id_rsa
  rsync -rltvhz -e "/usr/bin/ssh -o StrictHostKeyChecking=no -i /home/entrocim/.ssh/id_rsa" IoT_POD_Update@podupdate.iotwarez.com:/volume1/podsync/_info/updatescripts.sh /home/entrocim/IoT_Warez/  &&  chown -R entrocim:entrocim /home/entrocim/ && cp /root/.ssh/known_hosts /home/entrocim/.ssh/
  echo -e 'entrocim' > /etc/cron.allow
  sudo -H -u entrocim bash -c /home/entrocim/IoT_Warez/updatescripts.sh
  sudo -H -u entrocim bash -c "/home/entrocim/scripts/podupdate.sh > /tmp/$HOSTNAME'_podupdate_'`date '+\%b-\%d-\%Y'`.log 2>&1; /home/entrocim/scripts/sendlog.sh"
fi

#Add Cron Jobs for entrocim and root users
set -f
ECRON=$'05 04 * * * $HOME/IoT_Warez/updatescripts.sh; $HOME/scripts/podupdate.sh > /tmp/$HOSTNAME\'_podupdate_\'`date \'+\%b-\%d-\%Y\'`.log 2>&1; $HOME/scripts/sendlog.sh #Added by IoT Warez, LLC'
RCRON=$'00 04 * * * /home/entrocim/scripts/fail2ban-allstatus.sh #Added by IoT Warez, LLC'
if grep -Fqs "\$HOME/IoT_Warez/updatescripts.sh; \$HOME/scripts/podupdate.sh > /tmp/\$HOSTNAME'_podupdate_'`date '+\%b-\%d-\%Y'`.log 2>&1; \$HOME/scripts/sendlog.sh #Added by IoT Warez, LLC" /var/spool/cron/entrocim; then
  echo "Automatic Updates are already enabled..."
else
  if [ ! -f /var/spool/cron/entrocim ]; then
    echo -e "SHELL=/bin/bash\n"$ECRON > /var/spool/cron/entrocim
    chown entrocim:root /var/spool/cron/entrocim
    chmod 600 /var/spool/cron/entrocim
  fi
fi

if grep -Fqs "/home/entrocim/scripts/fail2ban-allstatus.sh #Added by IoT Warez, LLC" /var/spool/cron/root; then
  echo "Automatic Updates are already enabled..."
else
  if [ ! -f /var/spool/cron/root ]; then
    echo -e $RCRON > /var/spool/cron/root
    chown root:root /var/spool/cron/root
    chmod 600 /var/spool/cron/root
  fi
fi
set +f

#Create Firewall App Rule for EntroCIM
eCIMfw=`echo $eCIMfw | awk '{print tolower($0)}'`
if [ "$eCIMfw" == "y" ]; then
  echo "Adding New Firewall Rule to Active Zone of $GETFWZONE for Incoming TCP Port $port"
  echo ""
  firewall-cmd --zone=$GETFWZONE --add-port=$port/tcp --permanent
  sudo firewall-cmd --reload
fi

#Set http port in host
if [ -e $install_path/var/host/folio.trio ]; then
  sed -i -e 's/httpPort:.*/httpPort:'$port'/' $install_path/var/host/folio.trio
  echo "Auto Configuration of Port has succeeded..."
  # service entrocim restart
else
  echo "Problem with Auto Configuration of Port"
fi

echo -e "#!/bin/bash\nsudo -u entrocim java -cp ../lib/java/sys.jar -Dfan.home=../ fanx.tools.Fan finStackHost  >> ../entrocim.log 2>&1 &" > $install_path/bin/start.sh
chmod +x $install_path/bin/start.sh

auto_start=`echo $auto_start | awk '{print tolower($0)}'`

if [ $auto_start == "y" ]; then

  # set maximum memory allocated for EntroCIM
  HeapSize="'$heapmax'"
  # set the HTTP port EntroCIM listen on
  PortNumber="'$port'"
  # set the EntroCIM home folder
  HomeFolder='$install_path'

  JRE="java -Xmx$HeapSize"

echo '
[Unit]
Description=EntroCIM
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
PIDFile=/var/run/entrocim.pid
WorkingDirectory='$HomeFolder'
User=entrocim
Group=entrocim
Restart=always
TimeoutStartSec=1min
RestartSec=1min
ExecStart=/usr/bin/'$JRE' -cp '$HomeFolder'/lib/java/sys.jar: -Dfan.home='$HomeFolder' fanx.tools.Fan finStackHost >>/var/log/entrocim.log
KillMode=process
LimitNOFILE=200000

[Install]
WantedBy=multi-user.target' > /etc/init.d/entrocim
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


# Create OnChange Service restart on monitored lib/fan Folder

echo '#!/bin/sh
### BEGIN INIT INFO
# Provides:          Auto restart service on file change for EntroCIM
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO
# /etc/init.d/onchange

StartCMD="sudo /home/entrocim/scripts/onchange.sh"

PIDFile="/var/run/onchange.pid"
LogFile="/var/log/onchange.log"
# Touch the lock file
touch $PIDFile

# Determine user command
case "$1" in
  start)
    echo "Starting OnChange"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       $StartCMD >> $LogFile 2>&1 &
       echo $! > /var/run/onchange.pid
       exit 0
    else
       echo OnChange runs with pid: $CurPID
       echo type "/etc/init.d/onchange stop" to stop it first.
       exit 1
    fi
    ;;
  stop)
    echo "Stopping OnChange"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       echo OnChange is already stopped.
    else
      kill $CurPID
      rm $PIDFile
    fi
    ;;
  restart)
    echo "Restarting OnChange"
    CurPID=`cat $PIDFile`
    if [ -z "$CurPID" ]; then
       $StartCMD >> $LogFile 2>&1 &
       echo $! > /var/run/onchange.pid
       echo OnChange is restarted.
       exit 0
    else
      kill $CurPID
      rm $PIDFile
      $StartCMD >> $LogFile 2>&1 &
      echo $! > /var/run/onchange.pid
      echo OnChange is restarted.
      exit 0
    fi
    ;;
  status)
    echo "OnChange"
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
    echo "Usage: /etc/init.d/onchange {start|stop|restart|status}"
    exit 1
    ;;
esac

exit 0' > /etc/init.d/onchange
chmod 755 /etc/init.d/onchange

# bind the service
if [ -f "/usr/sbin/update-rc.d" ]; then
    update-rc.d onchange defaults > /dev/null
else
    chkconfig --add onchange > /dev/null
fi

echo '/var/log/onchange.log {
su root root
minsize 10M
weekly
rotate 12
compress
delaycompress
copytruncate
postrotate
    touch /var/log/onchange.log
endscript
}' > /etc/logrotate.d/onchange

# start the service
/etc/init.d/onchange restart

exit 0
