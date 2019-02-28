#!/bin/bash
gpio readall
echo "Bouncing relay " $1
gpio -g mode $1 OUT
gpio -g write $1 1
gpio readall
sleep 5
gpio -g write $1 0
gpio readall
echo "Done"
