#!/bin/bash
cd /home/pi/APC_TestTools
rm routes.txt
/home/pi/APC_TestTools/PatchRoute.pl $1
