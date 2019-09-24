#!/bin/bash
cd /home/pi/APC_TestTools
##  Request the first address
/home/pi/APC_TestTools/I2Cio.pl write 0x0f 0xA0 0x00
echo Device 0x00
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A0
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A1
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A2
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A3
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A4
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A5
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A6
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A7
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A8
echo  Device 0x01
/home/pi/APC_TestTools/I2Cio.pl write 0x0f 0xA0 0x01
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A1
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A2
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A3
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A4
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A5
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A6
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A7
/home/pi/APC_TestTools/I2Cio.pl read 0x0f 0x0A8
