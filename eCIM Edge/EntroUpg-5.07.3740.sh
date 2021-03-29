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

if [ ! -d "$install_path" ]; then
  echo -n "Please Specify the Entrocim install location i.e. '$install_path' : "
  read install_path
  if [ ! -d "$install_path" ]; then
    echo -e "Install location does not exist... Exiting"
    exit
  fi

elif [ -d "$install_path" ]; then
  echo -e "Found default install location of $install_path\n"
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMins
  eCIMins=`echo $eCIMins | awk '{print tolower($0)}'`
  if [ $eCIMins == "n" ]; then
    echo -n "Please Specify the Entrocim install location i.e. '$install_path' : "
    read install_path
    eCIMins="y"
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
if [ $eCIMupg == "y" ]; then
  mkdir -p ~/upgrade && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/$NXTLINK/download -O ~/upgrade/EntroCIM-$UPGV.zip
  mkdir -p ~/upgrade/$UPGV
  cd upgrade/$UPGV
  7z x ../EntroCIM-$UPGV.zip -aoa
  cd ../..
  cp -R ~/upgrade/$UPGV/$extract_folder/* $install_path/
  chown -R entrocim:entrocim $install_path/
  echo -e "Upgrade of EntroCIM Instance located @ $install_path has been completed...\n"
elif [ $eCIMupg == "n" ]; then
  echo -e "User Cancelled the Upgrade...\n"
  exit
fi
