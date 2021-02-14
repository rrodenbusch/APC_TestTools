#!/bin/bash
cd /home/pi
/home/pi/APC_TestTools/wrapPower.pl $2 >>scour.log 2>&1
gzip /home/pi/B827EB*.csv
/usr/bin/rsync -r /home/pi/B827EB* mthinx@$1:/extdata/power >>scour.log 2>&1

