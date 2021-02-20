#!/bin/bash
cd /home/pi
/home/pi/APC_TestTools/scourPower.pl >>scour.log 2>&1
gzip /home/pi/B827EB*.csv
/usr/bin/rsync --remove-source-file -rv /home/pi/B827EB*.csv* mthinx@$1:/extdata/power >>scour.log 2>&1

