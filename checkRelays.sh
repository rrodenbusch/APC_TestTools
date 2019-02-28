#!/bin/bash

echo "Checking NVN"
./I2Cio.pl read 0x21 0x09
gpio -g mode 11 out
gpio -g write 11 1
echo "NVN pulled down by RPi"
./I2Cio.pl read 0x21 0x09
read  Cont
gpio -g write 11 0
gpio -g mode 11 in
echo "NVN on"
read Cont
./I2Cio.pl read 0x21 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0xBF
./I2Cio.pl write 0x22 0x0A 0x40
./I2Cio.pl read 0x21 0x09
echo "NVN pulled down by IC"
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "NVN restored"
read Cont

echo "Checking Bridge"
./I2Cio.pl read 0x21 0x09
gpio -g mode 10 out
gpio -g write 10 1
echo "Bridge pulled down by RPi"
./I2Cio.pl read 0x21 0x09
read  Cont
gpio -g write 10 0
gpio -g mode 10 in
echo "Bridge on"
read Cont
./I2Cio.pl read 0x21 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0xEF
./I2Cio.pl write 0x22 0x0A 0x10
./I2Cio.pl read 0x21 0x09
echo "Bridge pulled down by IC"
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Bridge restored"
read Cont


echo "Checking Cams"
./I2Cio.pl read 0x21 0x09
gpio -g mode 22 out
gpio -g write 22 1
echo "Cams pulled down by RPi"
./I2Cio.pl read 0x21 0x09
read  Cont
gpio -g write 22 0
gpio -g mode 22 in
echo "Cams on"
read Cont
./I2Cio.pl read 0x21 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0xF7
./I2Cio.pl write 0x22 0x0A 0x08
./I2Cio.pl read 0x21 0x09
echo "Cams pulled down by IC"
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Cams restored"
read Cont

echo "Checking Sensors"
./I2Cio.pl read 0x21 0x09
gpio -g mode 27 out
gpio -g write 27 1
echo "Sensors pulled down by RPi"
./I2Cio.pl read 0x21 0x09
read  Cont
gpio -g write 27 0
gpio -g mode 27 in
echo "Sensors on"
read Cont
./I2Cio.pl read 0x21 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0xFB
./I2Cio.pl write 0x22 0x0A 0x04
./I2Cio.pl read 0x21 0x09
echo "Sensors pulled down by IC"
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Sensors restored"
read Cont

echo "Checking Arduino"
i2cdetect -y 1
./I2Cio.pl read 0x21 0x09
gpio -g mode 23 out
gpio -g write 23 1
echo "Arduino pulled down by RPi"
i2cdetect -y 1
read  Cont
gpio -g write 23 0
gpio -g mode 23 in
echo "Arduino on"
./I2Cio.pl read 0x21 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0xFE
./I2Cio.pl write 0x22 0x0A 0x01
i2cdetect -y 1
echo "Arduino pulled down by IC"
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Arduino restored"
read Cont

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

echo "Press enter to check Switch"
./I2Cio.pl read 0x21 0x09
gpio -g mode 17 out
gpio -g write 17 1
echo "Switch pulled down by RPi"
./I2Cio.pl read 0x21 0x09
sleep 2
gpio -g write 27 0
gpio -g mode 27 in
echo "Switch on"
read Cont
./I2Cio.pl read 0x21 0x09
read Cont
./I2Cio.pl write 0x22 0x00 0xFB
./I2Cio.pl write 0x22 0x0A 0x04
./I2Cio.pl read 0x21 0x09
echo "Switch pulled down by IC"
sleep 2
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Switch restored"
read Cont

echo "Press enter to check Pi"
./I2Cio.pl read 0x21 0x09
gpio -g mode 9 out
gpio -g write 9 1
echo "Switch pulled down by RPi"
./I2Cio.pl read 0x21 0x09
sleep 2
gpio -g write 9 0
gpio -g mode 9 in
echo "Pi on"
read Cont


