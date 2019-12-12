#!/bin/bash
echo Connect NVN to APC
echo Enter to Continue
read testVar
########################
/home/pi/APC_TestTools/queryI2C.pl
echo check Enter to Continue
read testVar
echo "######### Temps ###########"
/home/pi/APC_TestTools/readTemp
echo "########## Doors ##########"
/home/pi/APC_TestTools/readDoors
echo "############ dB ###########"
/home/pi/APC_TestTools/readDB
echo "########### Images ########"
/home/pi/APC_TestTools/rtailCSV 231 png
