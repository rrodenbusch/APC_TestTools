#!/bin/bash
while [ 1 ];  do
   /home/pi/APC_TestTools/I2Cio.pl read 0x0a 0x0a
   /home/pi/APC_TestTools/I2Cio.pl read 0x0a 0x0b
   sleep 5
done
