#!/bin/bash

echo " "
echo "---------------------------------- "
echo "NVN"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
gpio -g mode 11 out
gpio -g write 11 1
./I2Cio.pl read 0x21 0x09
echo "NVN pulled down by RPi"
echo "Enter to continue..."
read  Cont
gpio -g write 11 0
gpio -g mode 11 in
./I2Cio.pl read 0x21 0x09
echo "NVN on"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x00 0xBF
./I2Cio.pl write 0x22 0x0A 0x40
./I2Cio.pl read 0x21 0x09
echo "NVN pulled down by IC"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "NVN restored"
echo "Enter to continue..."
read Cont


echo " "
echo "---------------------------------- "
echo "Bridge"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
gpio -g mode 10 out
gpio -g write 10 1
./I2Cio.pl read 0x21 0x09
echo "Bridge pulled down by RPi"
echo "Enter to continue..."
read  Cont
gpio -g write 10 0
gpio -g mode 10 in
echo "Bridge on"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
./I2Cio.pl write 0x22 0x00 0xEF
./I2Cio.pl write 0x22 0x0A 0x10
./I2Cio.pl read 0x21 0x09
echo "Bridge pulled down by IC"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Bridge restored"
read Cont



echo " "
echo "---------------------------------- "
echo "Cameras"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
gpio -g mode 22 out
gpio -g write 22 1
echo "Cams pulled down by RPi"
./I2Cio.pl read 0x21 0x09
echo "Enter to continue..."
read  Cont
gpio -g write 22 0
gpio -g mode 22 in
./I2Cio.pl read 0x21 0x09
echo "Cams on"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x00 0xF7
./I2Cio.pl write 0x22 0x0A 0x08
./I2Cio.pl read 0x21 0x09
echo "Cams pulled down by IC"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Cams restored"
echo "Enter to continue..."
read Cont


echo " "
echo "---------------------------------- "
echo "Checking Sensors"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
gpio -g mode 27 out
gpio -g write 27 1
./I2Cio.pl read 0x21 0x09
echo "Sensors pulled down by RPi"
echo "Enter to continue..."
read  Cont
gpio -g write 27 0
gpio -g mode 27 in
./I2Cio.pl read 0x21 0x09
echo "Sensors on"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x00 0xFB
./I2Cio.pl write 0x22 0x0A 0x04
./I2Cio.pl read 0x21 0x09
echo "Sensors pulled down by IC"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Sensors restored"
echo "Enter to continue..."
read Cont



echo " "
echo "---------------------------------- "
echo "Checking Arduino"
echo "Enter to continue..."
read Cont
i2cdetect -y 1
./I2Cio.pl read 0x21 0x09
gpio -g mode 23 out
gpio -g write 23 1
i2cdetect -y 1
echo "Arduino pulled down by RPi"
echo "Enter to continue..."
read  Cont
gpio -g write 23 0
gpio -g mode 23 in
./I2Cio.pl read 0x21 0x09
sleep 2
i2cdetect -y 1
i2cdetect -y 1
echo "Arduino on"
read Cont
./I2Cio.pl write 0x22 0x00 0xFE
./I2Cio.pl write 0x22 0x0A 0x01
i2cdetect -y 1
echo "Arduino pulled down by IC"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Arduino restored"
echo "Enter to continue..."
read Cont



echo " "
echo "---------------------------------- "
echo "Checking NUC"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
./I2Cio.pl read 0x22 0x09
gpio -g mode 13 out
echo "NUC pulled down by RPi"
./I2Cio.pl read 0x21 0x09
./I2Cio.pl read 0x22 0x09
read  Cont
gpio -g mode 13 in
echo "Enter to continue..."
echo "NUC on"
./I2Cio.pl read 0x21 0x09
./I2Cio.pl read 0x22 0x09
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x00 0x7F
./I2Cio.pl read 0x21 0x09
echo "Nuc pulled down by IC"
echo "Enter to continue..."
read Cont
./I2Cio.pl write 0x22 0x00 0xFF
echo "NUC restored"


echo " "
echo "---------------------------------- "
echo "Ready to check Switch"
echo "Enter to continue..."
read Cont
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
./I2Cio.pl write 0x22 0x00 0xFC
./I2Cio.pl write 0x22 0x0A 0x02
./I2Cio.pl read 0x21 0x09
echo "Switch pulled down by IC"
echo "Pausing 2 seconds.."
sleep 4
./I2Cio.pl write 0x22 0x0A 0x00
./I2Cio.pl write 0x22 0x00 0xFF
./I2Cio.pl read 0x21 0x09
echo "Switch restored"
echo "Enter to continue..."
read Cont


echo " "
echo "---------------------------------- "
echo "Ready check Pi"
echo "Enter to continue..."
read Cont
./I2Cio.pl read 0x21 0x09
gpio -g mode 9 out
gpio -g write 9 1
echo "Pausing 2 seconds.."
echo "Pi pulled down by RPi"
./I2Cio.pl read 0x21 0x09
sleep 2
gpio -g write 9 0
gpio -g mode 9 in
echo "Pi on"
echo "Enter to continue..."
read Cont


