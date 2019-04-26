#!/bin/bash
while [ 1 ]; do
   cpu=$(</sys/class/thermal/thermal_zone0/temp)
   echo "GPU => $(/opt/vc/bin/vcgencmd measure_temp)"
   echo "CPU => $((cpu/1000))'C"
   sleep 5
done
