#!/bin/bash
D1=1
if [ $# -eq 1 ] ;
then
   D1=$1
fi
while [ 1 ]; do
   i2cdetect -y 1
   queryI2C.pl
   sleep $D1
done

