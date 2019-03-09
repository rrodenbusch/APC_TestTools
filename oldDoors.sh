#!/bin/bash
while [ 1 ]; do 
    ./I2Cio.pl read 0x08 0x03
    sleep 1
done

