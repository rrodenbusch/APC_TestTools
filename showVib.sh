#!/bin/bash
MAX=$2
MIN=-1*$2
/home/pi/APC_TestTools/plotMPU.pl $1 2>//dev/null | feedgnuplot --domain --nodataid --stream --xlen 10000 -line --nopoint --ymax $MAX --ymin $MIN --title "Vibration Gs $MAX"
