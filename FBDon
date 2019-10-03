#!/bin/bash
echo "Press Enter to Power On FBD"
read testVar
gpio -g mode 18 out
gpio -g write 18 1
gpio -g mode 23 out
gpio -g write 23 1
gpio -g mode 18 in
gpio -g mode 23 in
echo "FBD Powered On"
