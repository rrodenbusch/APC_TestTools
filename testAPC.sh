#!/bin/bash
/home/pi/APC_TestTools/i2c_testMPU.pl
/home/pi/APC_TestTools/queryI2C.pl
echo "run i2c_testMPU.pl and return"
echo "Enter to continue"
read var
gpio -g mode 24 out
gpio -g write 24 1
echo "Bridge Off: Enter to continue"
read var
gpio -g write 24 0
gpio -g mode 24 in
echo "Bridge On: Enter to continue"
gpio -g mode 18 out
gpio -g mode 23 out
gpio -g write 18 1
gpio -g write 23 1
echo "Cams & Sensors off: Enter to continue"
read var
gpio -g write 23 0
gpio -g write  18 0
gpio -g mode 23 in 
gpio -g mode 18 in
gpio -g mode 19 out
gpio -g write 19 0
echo "NVN off: Enter to continue"
read var
gpio -g mode 19 in
gpio -g mode 16 out
gpio -g write 16 0
gpio -g mode 26 out
gpio -g write 26 0
echo "NUC  off: Enter to continue"
read var
gpio -g mode 16 in
gpio -g mode 26 in
gpio -g mode 12 out
gpio -g write 12 1
echo "TNet off: Enter to continue"
read var
gpio -g write 12 0
gpio -g mode 12 in
gpio -g mode 19 out
gpio -g write 19 0
gpio -g mode 23 out
gpio -g write 23 1
echo "NVN & Cams off, swap out LED for real NVN"
read var
gpio -g mode 19 in
gpio -g write 18 0
gpio -g mode 18 in
gpio -g write 23 0
gpio -g mode 23 in
echo "NVN  & Cams on, let NVN boot"
echo "Enter to continue to testFBD"
read var
/home/pi/APC_TestTools/testFBD





