#!/bin/bash
#gpio readall
echo "What relay to bounce?"
read bcm
echo "What relay to sense?"
read sns
if [ $bcm -gt 0 ]
then 
   gpio -g mode $sns out
   gpio -g write $sns 0
   gpio -g mode $sns in
   sleep 1
   echo "Current sense.."
   gpio -g read $sns
   echo "Bouncing relay " $bcm
   gpio -g mode $bcm OUT
   gpio -g write $bcm 1
   echo "Sense after relay open"
   gpio -g read $sns
   sleep 5
   gpio -g write $bcm 0
   echo "Final sense"
   gpio -g read $sns
fi
echo "Done"
