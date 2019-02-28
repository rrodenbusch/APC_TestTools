#!/bin/bash

echo " "
echo "---------------------------------- "
echo "Ready to check Switch"
./I2Cio.pl read 0x21 0x09
gpio -g mode 17 out
gpio -g write 17 1
./I2Cio.pl read 0x21 0x09
echo "Switch pulled down by RPi"
sleep 4
gpio -g write 17 0
gpio -g mode 17 in
./I2Cio.pl read 0x21 0x09
echo "Switch on"
sleep 4
./I2Cio.pl write 0x22 0x00 0xFB
./I2Cio.pl write 0x22 0x0A 0x04
./I2Cio.pl read 0x21 0x09
echo "Switch pulled down by IC"
echo "Pausing 2 seconds.."
sleep 4
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Switch restored"
echo "Enter to continue..."
