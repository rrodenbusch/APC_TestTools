#!/bin/bash
while [ 1 ];  do
   /home/pi/APC_TestTools/I2Cio.pl read 0x0a 0x0b
   /home/pi/APC_TestTools/I2Cio.pl read 0x21 0x09
   sleep 1
done
