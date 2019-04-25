#!/bin/bash
while [ 1 ]; do
   /home/pi/APC_TestTools/I2Cio.pl read 0x0A 0x0A
   /home/pi/APC_TestTools/I2Cio.pl read 0x0A 0x0B
   sleep 2
done
