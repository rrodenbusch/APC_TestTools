#!/bin/bash
echo "Checking NUC"
./I2Cio.pl read 0x21 0x09
./I2Cio.pl read 0x22 0x09
gpio -g mode 13 out
echo "NUC pulled down by RPi"
./I2Cio.pl read 0x21 0x09
./I2Cio.pl read 0x22 0x09
read  Cont
gpio -g mode 13 in
echo "NUC on"
./I2Cio.pl read 0x21 0x09
./I2Cio.pl read 0x22 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0x7F
./I2Cio.pl read 0x21 0x09
echo "Nuc pulled down by IC"
read Cont
./I2Cio.pl write 0x22 0x00 0xFF
echo "NUC restored"
