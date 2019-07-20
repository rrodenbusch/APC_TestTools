#!/bin/bash
/home/pi/APC_TestTools/plotDB.pl $1 -m 2>//dev/null | feedgnuplot --domain --nodataid --stream --xlen 10000 -line --nopoint --ymax $1 --title "Peak $2"
