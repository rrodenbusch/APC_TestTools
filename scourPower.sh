#!/bin/bash
cd /home/pi
/home/pi/APC_TestTools/scourPower.pl >>scour.log 2>&1
/usr/bin/rsync -r /home/pi/B827EB* mthinx@$1:/extdata/power >>scour.log 2>&1

