#!/bin/bash
D1=10
if [ $# -eq 1 ] ;
then
   D1=$1
fi
while [ 1 ]; do
   #i2cdetect -y 1
   getFBDUID | head -1
   sleep $D1
done

