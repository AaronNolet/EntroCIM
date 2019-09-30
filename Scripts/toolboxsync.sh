#!/bin/bash
rsync -rltvhz --del -e "/usr/bin/ssh -i /home/Toolbox_Sync/.ssh/id_rsa" Toolbox_Sync@podupdate.iotwarez.com:/volume1/Safety/_ToolboxAttachments/ /home/iotwarez/scripts/Toolbox_Topics/
