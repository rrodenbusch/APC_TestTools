#!/bin/bash
lognames=('/home/pi/Watch.log' '/home/pi/RPi/WatchDog.log' '/home/pi/power.log' 
          '/home/mthinx/Watch.log' '/home/mthinx/WatchNUC.log')
# rotate @ 200 Meg
MaxFileSize=209715200
movelog() {
   if [ -f $1 ]; then
      file_size=`du -b $1 | tr -s '\t' ' ' | cut -d' ' -f1`
      echo "$1 file size $file_size vs Max $MaxFileSize"
      if [ $file_size -gt $MaxFileSize ]; then
          /usr/bin/savelog $1
      fi
   fi
}

for fname in "${lognames[@]}"
do
   movelog  $fname 
done
