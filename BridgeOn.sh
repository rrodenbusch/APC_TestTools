#!/bin/bash
gpio -g write 24 0
gpio -g mode 24 in
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x00 0xFF
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x0A 0x00

