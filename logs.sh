#!/bin/bash
lognames=('/home/pi/Watch.log','/home/pi/RPi/WatchDog.log','/home/pi/power.log',
          '/home/mthinx/Watch.log','/home/mthinx/WatchNUC.log')
# rotate @ 200 Meg
MaxFileSize=209715200
movelog() {
   if [ [ -e $1 ] ]; then
      file_size=`du -b /script_logs/test.log | tr -s '\t' ' ' | cut -d' ' -f1`
      if [ $file_size -gt $MaxFileSize ]; then /usr/bin/savelog $1; fi
   fi
}

for $fname in "${lognames[@]}"; do
   movelog($fname)
done
