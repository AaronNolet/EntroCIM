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
source /etc/os-release

if [[ $ID == "ubuntu" ]]; then
  OSFW="ufw"
  INST_CMD="apt-get"
  if [ $(echo " 18.0 > $VERSION_ID " | bc -l ) ] && [ $(echo " 18.9 < $VERSION_ID " | bc -l ) ]; then
    OSID="$ID $VERSION_ID"
  elif [ $(echo " 20.0 > $VERSION_ID " | bc -l ) ] && [ $(echo " 20.9 < $VERSION_ID " | bc -l ) ]; then
    OSID="$ID $VERSION_ID"
  fi
elif [[ $ID == "ol" ]]; then
  OSFW="firewalld"
  INST_CMD="yum"
  REPO_SRC="https://dl.fedoraproject.org/pub/epel/"
  if [ $(echo " 7.0 > $VERSION_ID " | bc -l ) && $(echo " 7.9 < $VERSION_ID " | bc -l ) ]; then
    OSID="$ID $VERSION_ID"
    REPO_REL="epel-release-latest-7.noarch.rpm"
  elif [ $(echo " 8.0 > $VERSION_ID " | bc -l ) && $(echo " 8.9 < $VERSION_ID " | bc -l ) ]; then
    OSID="$ID $VERSION_ID"
    REPO_REL="epel-release-latest-8.noarch.rpm"
  fi
fi

echo "Installing on: $OSID"

HOSTNAME=$(hostname)
#EntroCIM NXTLINK Versions:
# 5.0.7.3740_FoS "djkDr5xxrqAPaES"
# 5.0.5.3161_FoS "apagktAQg3CpWje"
NXTLINK="djkDr5xxrqAPaES"

# FOG Code during install needs to match with case start of file followed by _DCLinuxAgent.zip
NXTFOGLINK="3oiWJeBwtQFbHXM"
extract_folder="EntroCIM"

#clear

echo "**********************************"
echo "***     EntroCIM Installer     ***"
echo "**********************************"
echo ""
echo "Installing EntroCIM AI on $PRETTY_NAME with $OSFW Firewall..."
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

wget $REPO_SRC$REPO_REL
$INST_CMD install -y $REPO_REL -q
$INST_CMD update -y -q
$INST_CMD install -y p7zip.x86_64 p7zip-plugins.x86_64 fail2ban java-11-openjdk.x86_64 htop.x86_64 -q

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

echo -e "#!/bin/bash\nsudo -u entrocim java -cp ../lib/java/sys.jar:/lib/java/jline.jar: -Dfan.home=../ fanx.tools.Fan finStackHost  >> ../entrocim.log 2>&1 &" > $install_path/bin/start.sh
echo '#!/bin/bash

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
    while pgrep java -u entrocim >/dev/null; do
      sleep 10;
    done
    service finstack start
    echo "Completed..."
  elif [ "$SkyFin" == "Sky" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting skyspark Service"
    service skyspark stop
    while pgrep java -u entrocim >/dev/null; do
      sleep 10;
    done
    service skyspark start
    echo "Completed..."
  elif [ "$SkyFin" == "eCIM" ]; then
    echo date '+%d/%m/%Y %H:%M:%S'
    echo "Restarting EntroCIM Service"
    service entrocim stop
    while pgrep java -u entrocim >/dev/null; do
      sleep 10;
    done
    service entrocim start
    echo "Completed..."
  fi
  echo "$PIDFile - $CurPID" > /tmp/PIDlog.log
fi
cp /tmp/watchfile2 /tmp/watchfile
done
'> $install_path/bin/onchange.sh

chmod +x $install_path/bin/start.sh $install_path/bin/onchange.sh

auto_start=`echo $auto_start | awk '{print tolower($0)}'`

echo '[Unit]
Description=EntroCIM
After=syslog.target network.target

[Service]
SuccessExitStatus=143
WorkingDirectory=$install_path
LimitNOFILE=200000
PIDFile="/var/run/entrocim.pid"
LogFile="/var/log/entrocim.log"
Type=forking
ExecStart=$install_path/bin/start.sh
ExecStop=/bin/kill -15 $MAINPID

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/entrocim.service
chmod 755 /etc/init.d/entrocim.service

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


echo '[Unit]
Description=OnChange
After=syslog.target network.target

[Service]
SuccessExitStatus=143
PIDFile="/var/run/onchange.pid"
LogFile="/var/log/onchange.log"
Type=forking
ExecStart=$install_path/bin/onchange.sh
ExecStop=/bin/kill -15 $MAINPID

[Install]
WantedBy=multi-user.target'  > /etc/systemd/system/onchange.service
chmod 755 /etc/init.d/onchange.service

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
if [ $auto_start == "y" ]; then
systemctl daemon-reload
systemctl enable entrocim
systemctl enable onchange
systemctl start entrocim
systemctl start onchange
fi

exit 0
