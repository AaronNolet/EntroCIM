#!/bin/bash
# Stop on error
set -e
# Install a trap to catch errors and clean-up temp files
trap 'echo "Installer terminated. Exit.";' INT TERM EXIT
# rm -f -r ./.tmp/'

#Set Vars
HOSTNAME=$(hostname)
#EntroCIM NXTLINK Versions:

NXTLINK="WNcWHqHNLd8EWJq"
UPGV="5.0.7.3740"
install_path="/opt/entrocim"
extract_folder="EntroCIM"
pkg_folder="/home/entrocim/upgrade"


clear

echo -e "$(tput setaf 6)**********************************"
echo -e "***     EntroCIM Updater       ***"
echo -e "**********************************\n\n$(tput sgr 0)"


if [ ! -d "$install_path" ]; then
  echo -n "$(tput setaf 6)Please Specify the Entrocim install location i.e. '$install_path' : $(tput sgr 0)"
  read install_path
  if [ ! -d "$install_path" ]; then
    echo -e "$(tput setaf 1)Install location does not exist... Exiting$(tput sgr 0)\n"
    exit
  else
    eCIMins="n"
  fi

elif [ -d "$install_path" ]; then
  echo -e "$(tput setaf 2)Found default install location of $install_path\n$(tput sgr 0)"
  tput setaf 3
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMins
  tput sgr 0
  eCIMins=`echo $eCIMins | awk '{print tolower($0)}'`
  if [ $eCIMins == "n" ]; then
    tput setaf 3
    echo -n "Please Specify the Entrocim install location i.e. '$install_path' : "
    read install_path
    tput sgr 0
    echo -e "$(tput setaf 2)New Install Path set to '$install_path'\n$(tput sgr 0)"
    if [ ! -d "$install_path" ]; then
      echo -e "$(tput setaf 1)Install location does not exist... Exiting$(tput sgr 0)\n"
      exit
    fi
  fi
fi
if [ $eCIMins == "y" ]; then
  eCIMupg="y"
else
  tput setaf 3
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMupg
  eCIMupg=`echo $eCIMupg | awk '{print tolower($0)}'`
  tput sgr 0
fi

if [ ! -d "$install_path/lib" ] || [ ! -d "$install_path/var" ]; then
  echo -e "$(tput setaf 1)Install location Sub-Folders do not exist... Exiting$(tput sgr 0)\n"
  exit
fi

if [ $eCIMupg == "y" ]; then
  BKSRC="$install_path/lib $install_path/var/brand"
  BKDST="$pkg_folder/$UPGV/Backup"
  BKFN=EntroBAK-$(date +%F).tgz
  mkdir -p $BKDST
  mkdir -p $pkg_folder/$UPGV && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/$NXTLINK/download -O $pkg_folder/$UPGV/EntroCIM-$UPGV.zip
  mkdir -p $pkg_folder/$UPGV
  cd $pkg_folder/$UPGV
  if [ -e /var/run/entrocim.pid ]; then
    service entrocim stop
    echo -e "$(tput setaf 2)Shutting Down EntroCIM Service..."
    while [ -e /var/run/entrocim.pid ]
    do
        echo -e "$(tput setaf 3)Waiting for EntroCIM Service shutdown..."
        sleep 5s
    done
    echo -e "$(tput setaf 2)EntroCIM Service has shutdown... Continuing...$(tput sgr 0)\n"
  fi

  if [ -e /var/run/onchange.pid ]; then
    service onchange stop
    echo -e "$(tput setaf 2)Shutting Down OnChange Service..."
    while [ -e /var/run/onchange.pid ]
    do
        echo -e "$(tput setaf 3)Waiting for OnChange Service shutdown..."
        sleep 5s
    done
    echo -e "$(tput setaf 2)OnChange Service has shutdown... Continuing...$(tput sgr 0)\n"
  fi

  echo -e "$(tput setaf 2)Backing up important files to $BKDST/$BKFN$(tput sgr 0)"
  tar -cf $BKDST/$BKFN $BKSRC
  if [ $? -eq 0 ]; then
    echo -e "$(tput setaf 2)Success...$(tput sgr 0)"
    rm -R $install_path/lib/fan/
  else
    echo -e "$(tput setaf 1)Failure...$(tput sgr 0)"
  fi
  7z x EntroCIM-$UPGV.zip -aoa
  cp -R $pkg_folder/$UPGV/$extract_folder/* $install_path/
  chown -R entrocim:entrocim $install_path/
  echo -e "$(tput setaf 2)Upgrade of EntroCIM Instance located @ $install_path has been completed...\n"
  if [ -e /etc/init.d/entrocim ]; then
    echo -e "Starting the Entrocim Service...\n"
    service entrocim start
  fi
  if [ -e /etc/init.d/onchange ]; then
    echo -e "Starting the OnChange Service...\n"
    service onchange start
  fi
  tput sgr 0
elif [ $eCIMupg == "n" ]; then
  echo -e "$(tput setaf 3)User Cancelled the Upgrade...$(tput sgr 0)\n"
  exit
fi
