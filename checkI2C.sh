#!/bin/bash

while [ 1 ]; do
   i2cdetect -y 1
   queryI2C.pl
   sleep 1
done

