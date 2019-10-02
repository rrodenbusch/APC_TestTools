#!/bin/bash
echo "Press Enter to Power Off FBD"
read testVar
gpio -g mode 18 out
gpio -g write 18 1
gpio -g mode 23 out
gpio -g write 23 1
echo "FBD Powered Off"
