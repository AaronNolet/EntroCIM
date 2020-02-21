#!/bin/bash
HOSTNAME=$(hostname)
DATE=`date +%b-%d-%Y`
RHOST=IoT_POD_Update@podupdate.iotwarez.com
FILEKEEP=`cat /tmp/keep.log`

echo $FILEKEEP

/usr/bin/ssh -t -i $HOME/.ssh/id_rsa" $RHOST:/volume1/podsync/_backups/$HOSTNAME/ << EOF

if (($?>0)); then
  echo 'Cant find work dir... exiting'
  exit
fi

for i in *; do
  if ! grep -qxFe "$i" $FILEKEEP; then
  echo "Deleting: $i"
# rm "$i"
fi
done
EOF
