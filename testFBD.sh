#!/bin/bash
#echo Connect NVN to APC
#echo Enter to Continue
#read testVar
########################
$HOME/APC_TestTools/i2c_testMPU.pl
$HOME/APC_TestTools/queryI2C.pl
echo check Enter to Continue
read testVar
echo "######### Temps ###########"
$HOME/pi/APC_TestTools/readTemp
echo "########## Doors ##########"
$HOME/pi/APC_TestTools/readDoors
echo "############ dB ###########"
$HOME/pi/APC_TestTools/readDB
echo "########### Images ########"
$HOME/pi/APC_TestTools/rtailCSV 231 png
