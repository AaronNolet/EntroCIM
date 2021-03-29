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

if [ ! -d "$install_path" ]; then
  echo -n "Please Specify the Entrocim install location i.e. '$install_path' : "
  read install_path
  if [ ! -d "$install_path" ]; then
    echo -e "Install location does not exist... Exiting"
    exit
  else
    eCIMins="n"
  fi

elif [ -d "$install_path" ]; then
  echo -e "Found default install location of $install_path\n"
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMins
  eCIMins=`echo $eCIMins | awk '{print tolower($0)}'`
  if [ $eCIMins == "n" ]; then
    echo -n "Please Specify the Entrocim install location i.e. '$install_path' : "
    read install_path
    echo -e "New Install Path $install_path\n"
    if [ ! -d "$install_path" ]; then
      echo -e "Install location does not exist... Exiting"
      exit
    fi
  fi
fi
if [ $eCIMins == "y" ]; then
  eCIMupg="y"
else
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMupg
  eCIMupg=`echo $eCIMupg | awk '{print tolower($0)}'`
fi

if [ ! -d "$install_path/lib" ] || [ ! -d "$install_path/var" ]; then
  echo -e "Install location subfolders do not exist... Exiting"
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
  echo "tar -cf $BKDST/$BKFN -C $BKSRC"
  tar -cf $BKDST/$BKFN -C $BKSRC
  7z x EntroCIM-$UPGV.zip -aoa
  cp -R $pkg_folder/$UPGV/$extract_folder/* $install_path/
  chown -R entrocim:entrocim $install_path/
  echo -e "Upgrade of EntroCIM Instance located @ $install_path has been completed...\n"
elif [ $eCIMupg == "n" ]; then
  echo -e "User Cancelled the Upgrade...\n"
  exit
fi
