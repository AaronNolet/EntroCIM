#!/bin/bash
echo -e "\nWritting File Audits... \n\n"

sudo systemctl status onchange.service >> ~/tmp.log
echo -e "Run on: `date`\n\n Pre-Service Status:\n" >> ~/audit.log
head ~/tmp.log -n3 >> ~/audit.log
rm ~/tmp.log
echo -e "\n\nEntroCIM Log (last 25 lines):\n" >> ~/audit.log
tail /var/log/entrocim.log -n25 >> ~/audit.log

echo -e "Restarting Service... Please hold.\n\n"

sudo systemctl restart onchange.service

sleep 5

sudo systemctl status onchange.service >> ~/tmp.log
echo -e "\n\n Post-Service Status:\n" >> ~/audit.log
head ~/tmp.log -n3 >> ~/audit.log
echo -e "\n**********************************************************************************************************\n\n" >> ~/audit.log
if grep -Fxq "Active: active (running)" ~/tmp.log; then
  echo -e "Service Restart Completed successfully...\n"
else
  echo -e "*** Service May have not started correctly... Please review...\n"
fi

rm ~/tmp.log
