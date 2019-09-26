#!/bin/bash
gpio -g mode 24 out
gpio -g write 24 1
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x0A 0x04
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x00 0xFB

