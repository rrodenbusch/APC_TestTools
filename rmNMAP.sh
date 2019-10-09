!#/bin/bash
cd /home/pi/RPi
echo "remove xml"
find . -name  '*.xml' | xargs sudo rm -f
echo "remove txt"
find . -name '*.txt' | xargs sudo rm -f

