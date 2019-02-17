#!/bin/bash

while [ 1 ]; do
   /home/pi/APC_TestTools/I2Cio.pl read 0x21 9
   sleep 1
done


