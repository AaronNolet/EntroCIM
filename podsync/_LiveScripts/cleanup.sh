#!/bin/bash
HOSTNAME=$(hostname)
DATE=`date +%b-%d-%Y`
CHECKDIR="var"
BACKNUM="1"
RHOST=IoT_POD_Update@podupdate.iotwarez.com
FILEKEEP=`cat /tmp/keep.log`

echo $FILEKEEP

/usr/bin/ssh -i $HOME/.ssh/id_rsa" $RHOST:/volume1/podsync/_backups/$HOSTNAME/ << EOF

# Exit if the directory isn't found.
if (($?>0)); then
  echo "Can't find work dir... exiting"
  exit
fi

for i in *; do
  if ! grep -qxFe "$i" $FILEKEEP; then
  echo "Deleting: $i"
# rm "$i"
fi
done
EOF
