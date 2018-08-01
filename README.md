# update_dns
This script can be used on a OpenWRT or LEDE router to update a DNS record on your CPanel account pointing to your homerouter. 
Say home.example.com points to your routers public IP adress so it can be used for easy accessing a private VPN or webserver.
It's an alternative for services like dyndns.
If you have a domain with a webhosting account managed by CPanel access this script can be used to maintain such a service.
It finds out your IP by querying a small php script on your hostingaccount and checks if your record needs updating. If so it will do the job for you.

## Installation
- Fitst create an 'A' record for your service like home.example.com and enter an ipnumber matching your current router's external ip adress. Chose a low ttl time for your record, say 3600. This is advisable so the caching of your DNS record will not stay behind to long.
- Place the file myip.php on your hostingaccount and test it to be shure it returns your public IP address.
- Copy the 'settings.ini.example' to 'settings.ini' and update the contents to your situation.
- Run the script 'update_dns.sh' and see the magic.
- If successfully run you can add it to your routers crontab to run every 5 minutes or so.

## Specifics for LEDE/OpenWRT
This script is written for the 'ash' shell so it can be run on a LEDE or OpenWRT router. Change the line '#!/bin/ash' to '#!/bin/bash' to make it compatible with your version of Linux.
