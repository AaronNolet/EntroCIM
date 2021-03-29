#!/bin/bash
# Stop on error
set -e
# Install a trap to catch errors and clean-up temp files
trap 'echo "Installer terminated. Exit.";' INT TERM EXIT
# rm -f -r ./.tmp/'

#Set Vars
HOSTNAME=$(hostname)
#EntroCIM NXTLINK Versions:
install_path="/opt/entrocim"
NXTLINK=""



if [ -d "$install_path" ]; then
  echo -e "Found default install location of $install_path\n"
  echo -n "Would you like to upgrade the EntroCIM instance located @ $install_path (N/y): "
  read eCIMins
  echo ""
  eCIMins=`echo $eCIMins | awk '{print tolower($0)}'`
  if [ $eCIMins == "n" ]; then
    echo -n "Please Specify the Entrocim install location i.e. '$install_path' : "
    read install_path
    echo -e "New Install Path $install_path\n"
  fi
  echo -e "Install Path $install_path\n"
fi

#eCIMupg=`echo $eCIMupg | awk '{print tolower($0)}'`
#if [ $eCIMupg == "y" ]; then
#  mkdir -p ~/upgrade && wget https://nextcloud.heptasystems.com:8443/nextcloud/index.php/s/$NXTLINK/download -O ~/entrocim/EntroCIM.zip
#  cd entrocim
#  7z x EntroCIM.zip -aoa
#  cd ..
#  cp -R ~/upgrade/$extract_folder/* $install_path/
#  chown -R entrocim:entrocim $install_path/
#elif [ $eCIMupg == "n" ]; then
