#!/bin/bash

recipient="s.clark@heptasystems.com,a.nolet@heptasystems.com"
sender="toolbox@heptasystems.com"
ffolder="Toolbox_Topics"
rndmatt=$( ls $HOME/scripts/Toolbox_Topics/*.pdf | sed 's#.*/##' | shuf -n 1 )
DATE=`date +%A", "%B" "%d", "%Y`

(echo -e "Attached is todays daily Toolbox meeting.\n\nThank you all for attending today's safety discussions.\n\nIf anyone has questions or concerns on today's meeting, please contact your safety manager.\n\n\nSincerly,\nThe Hepta Control Systems Safety Team"; uuencode "$HOME/scripts/$ffolder/$rndmatt" "$rndmatt") | mail -a "X-Priority:1" -s "HCS Toolbox Meeting - $DATE" $recipient -r $sender
