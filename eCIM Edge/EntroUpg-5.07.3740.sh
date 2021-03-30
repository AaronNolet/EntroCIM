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
  echo -e "$(tput setaf 2)Found default install location of $install_path\n\n$(tput sgr 0)"
  echo -e "$(tput setaf 3)"
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMins
  echo -e "$(tput sgr 0)"
  eCIMins=`echo $eCIMins | awk '{print tolower($0)}'`
  if [ $eCIMins == "n" ]; then
    echo -e "$(tput setaf 3)"
    echo -n "$(tput setaf 3)Please Specify the Entrocim install location i.e. '$install_path' : $(tput sgr 0)"
    read install_path
    echo -e "$(tput sgr 0)"
    echo -e "$(tput setaf 2)\nNew Install Path $install_path\n$(tput sgr 0)"
    if [ ! -d "$install_path" ]; then
      echo -e "$(tput setaf 1)Install location does not exist... Exiting$(tput sgr 0)\n"
      exit
    fi
  fi
fi
if [ $eCIMins == "y" ]; then
  eCIMupg="y"
else
  echo -n "$(tput setaf 3)Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): $(tput sgr 0)"
  read eCIMupg
  eCIMupg=`echo $eCIMupg | awk '{print tolower($0)}'`
  echo ""
fi

if [ ! -d "$install_path/lib" ] || [ ! -d "$install_path/var" ]; then
  echo -e "$(tput setaf 1)Install location subfolders do not exist... Exiting$(tput sgr 0)\n"
  exit
fi

if [ $eCIMupg == "y" ]; then
  BKSRC="$install_path/lib $install_path/var/brand"
  BKDST="$pkg_folder/$UPGV/Backup"
  BKFN=EntroBAK-$(date +%-Y%-m%-d)-$(date +%-T).tgz
  mkdir -p $BKDST
  mkdir -p $pkg_folder/$UPGV && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/$NXTLINK/download -O $pkg_folder/$UPGV/EntroCIM-$UPGV.zip
  mkdir -p $pkg_folder/$UPGV
  cd $pkg_folder/$UPGV
  if [ -e /var/run/entrocim.pid ]; then
    service entrocim stop
    echo -e "$(tput setaf 2)Shutting Down EntroCIM Service...\n"
    while [ true ]
    do
      pid=$(cat /var/run/entrocim.pid)
      if [[ -n "$pid" && $(ps -p $pid | wc -l) -eq 2 ]]; then
        echo -e "$(tput setaf 3)Waiting for EntroCIM Service shutdown...\n"
        sleep 5s
      fi
      echo -e "$(tput setaf 2)EntroCIM Service has shutdown... Continuing...$(tput sgr 0)\n"
    done
  fi

  if [ -e /var/run/onchange.pid ]; then
    service entrocim stop
    echo -e "$(tput setaf 2)Shutting Down OnChange Service...\n"
    while [ true ]
    do
      pid=$(cat /var/run/onchange.pid)
      if [[ -n "$pid" && $(ps -p $pid | wc -l) -eq 2 ]]; then
        echo -e "$(tput setaf 3)Waiting for OnChange Service shutdown...\n"
        sleep 5s
      fi
      echo -e "$(tput setaf 2)OnChange Service has shutdown... Continuing...$(tput sgr 0)\n"
    done
  fi

  echo "tar -cf $BKDST/$BKFN -C $BKSRC"
  tar -cf $BKDST/$BKFN -C $BKSRC
  7z x EntroCIM-$UPGV.zip -aoa
  cp -R $pkg_folder/$UPGV/$extract_folder/* $install_path/
  chown -R entrocim:entrocim $install_path/
  echo -e "Upgrade of EntroCIM Instance located @ $install_path has been completed...\n"
  elif [ $eCIMupg == "n" ]; then
    echo -e "$(tput setaf 3)User Cancelled the Upgrade...$(tput sgr 0)\n"
    exit
  fi
