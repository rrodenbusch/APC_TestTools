#!/bin/bash
gpio -g mode 19 out
gpio -g write 19 0
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x0A 0x00
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x00 0xEF

