#!/bin/bash
gpio readall
echo "What relay to bounce?"
read bcm
if [ $bcm -gt 0 ]
then 
   echo "Bouncing relay " $bcm
   gpio -g mode $bcm OUT
   gpio -g write $bcm 1
   gpio readall
   sleep 5
   gpio -g write $bcm 0
   gpio readall
fi
echo "Done"
