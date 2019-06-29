#!/bin/bash
FNAME=`ls -Art /home/pi/I2C/i2cdata/MPU/*.csv | tail -n 1`
tail -1 $FNAME

