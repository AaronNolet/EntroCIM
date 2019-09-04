#!/bin/bash
serverup=$(uptime -p | cut -d " " -f2-)
curl http://127.0.0.1:8085 -s -f -o /dev/null || printf "EntroCIM Service is down @ London Life.\n\nServer Uptime: $serverup" | mail -s "EntroCIM is down @ London Life" service@heptasystems.com
