#!/bin/bash

sites=( "https://PaaS-01.iotwarez.com" "https://PaaS-02.iotwarez.com" "https://PaaS-Dev-01.iotwarez.com" )
recipient="itsupport@heptasystems.com"
sender="helpdesk@heptasystems.com"
notifyonce="service@heptasystems.com"

for i in "${sites[@]}"
do
  si=${i/*\/\//}
  ssi=${si/.*/}
  curl $i -s -f -o /dev/null
  if [ 0 -ne $? ]; then
    echo -e "$ssi is DOWN!!!"

    #Notify based on each crontab run
    if [ -e /tmp/$ssi.dwn ]; then
      printf "**EMERGENCY** - EntroCIM Service is down @ $i\n\nNotifications will continue until problem has been resolved!!!" | mail -a "X-Priority:1" -s "**EMERGENCY** $ssi - EntroCIM Service is down." $recipient -r $sender
      echo -e "Send Email to $recipient"
    #Notify Once until fixed.
    else
      curl $i -s -f -o /dev/null || touch /tmp/$ssi.dwn
      printf "**EMERGENCY** - EntroCIM Service is down @ $i\n\n" | mail -a "X-Priority:1" -s "**EMERGENCY** $ssi - EntroCIM Service is down." $notifyonce,$recipient -r $sender
      echo -e "Send Email to $notifyonce and $recipient"
    fi

  else
    echo -e "$ssi is UP!!!"

     if [ -e /tmp/$ssi.dwn ]; then
      rm /tmp/$ssi.dwn
      printf "**RESTORED** - EntroCIM Service @ $i has been resolved!!!" | mail -a "X-Priority:1" -s "**RESTORED** $ssi - EntroCIM Service has been restored." $notifyonce,$recipient -r $sender
     fi
  fi
echo ""
#  curl $i -s -f -o /dev/null || printf "**EMERGENCY** - EntroCIM Service is down @ $i\n\nNotifications will continue until problem has been resolved!!!" | mail -s "**EMERGENCY** $ssi - EntroCIM Service is down." $recipient -r $sender
done
