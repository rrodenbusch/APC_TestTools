/home/pi/APC_TestTools/BridgeOn.pl
#!/bin/bash
/home/pi/APC_TestTools/queryI2C.pl
echo "Enter to continue"
read var
/home/pi/APC_TestTools/i2c_testMPU.pl
echo "Enter to continue"
read var
/home/pi/APC_TestTools/BridgeOff.sh
echo "Bridge Off: Enter to continue"
read var
/home/pi/APC_TestTools/BridgeOn.pl
echo "Bridge On: Enter to continue"
gpio -g mode 18 out
gpio -g mode 23 out
gpio -g write 18 1
gpio -g wire 23 1
echo "Cams & Sensors off: Enter to continue"
gpio -g write 23 0
gpio -g write  18 0
gpio -g mode 23 in 
gpio -g mode 18 in
echo "Enter to continue"
gpio -g mode 19 in
echo "NVN off: Enter to continue"
read var
gpio -g mode 16 in
gpio -g mode 26 in
echo "NVN  off: Enter to continue (TNET will bounce)"
read var
gpio -g mode 12 out
gpio -g write 12 1
sleep 3
gpio -g write 12 0
gpio -g mode 12 in
echo "Enter to continue to testFBD"
/home/pi/APC_TestTools/testFBD.sh





