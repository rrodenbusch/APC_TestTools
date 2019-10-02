#!/bin/bash
/home/pi/APC_TestTools/stopRPi.pl kill
cd /home/pi/I2C/i2cdata
rm ./door/*
rm ./dB/*
rm ./gpio/*
rm ./i2c/*
rm ./MPU/*
rm ./temp/*
rm ./voltage/*
/home/pi/APC_TestTools/startPi
gpio -g mode 18 out
gpio -g write 18 0
gpio -g mode 18 in
gpio -g mode 23 out
gpio -g write 23 0
gpio -g mode 23 in
gpio -g mode 19 in
sleep 4
echo Connect NVN to APC
echo Enter to Continue 
read testVar
#/home/pi/APC_TestTools/i2c_testMPU.pl
#echo Enter to Continue
read testVar
/home/pi/APC_TestTools/queryI2C.pl
########################
/home/pi/APC_TestTools/i2c_1WireAddy.pl
echo check Doors  Enter to Continue
read testVar
/home/pi/APC_TestTools/rtailCSV 221 door
echo check dB  Enter to Continue
/home/pi/APC_TestTools/rtailCSV 221 dB
echo check Temp Enter to Continue
/home/pi/APC_TestTools/rtailCSV 221 temp
echo check cams  Enter to Continue
/home/pi/APC_TestTools/rtailCSV 231 png
gpio -g mode 23 out
gpio -g write 23 1
gpio -g mode 18 out
gpio -g write 18 1
/home/pi/APC_TestTools/stopRPi.pl kill

