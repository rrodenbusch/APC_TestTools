#!/bin/bash
/home/pi/APC_TestTools/plotDB.pl $1 | feedgnuplot --domain --nodataid --stream --xlen 10000 -line --nopoint --ymax $2
