#!/bin/bash
/home/pi/APC_TestTools/plotDB.pl -p $1 2>//dev/null | feedgnuplot --domain --nodataid --stream --xlen 10000 -line --nopoint --ymax $1 --title "Peak $2"
