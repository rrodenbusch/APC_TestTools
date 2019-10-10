#!/bin/bash
cd /home/pi/RPi
echo "remove xml"
find . -name  '*.xml' | xargs rm -f
echo "remove txt"
find . -name '*.txt' | xargs rm -f

