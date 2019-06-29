#!/bin/bash
/home/pi/APC_TestTools/plotMPU.pl $1 2>//dev/null | feedgnuplot --domain --nodataid --stream --xlen 10000 -line --nopoint --ymax 10 --ymin -10 --title "Vibration Gs"
