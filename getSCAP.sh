#!/bin/bash
while [ 1 ];  do
   /home/pi/APC_TestTools/I2Cio.pl read 0x0a 0x0b
   gpio -g read 21
   /home/pi/APC_TestTools/I2Cio.pl read 0x21 0x09
   gpio -g read 19
   gpio -g read 16
   sleep 1
done
