#!/bin/bash
MAX=$2
MIN=-1*$2
$HOME/APC_TestTools/plotMPU.pl $1 2>//dev/null | feedgnuplot --domain --nodataid --stream --xlen 10 -line --nopoint --ymax $MAX --ymin $MIN --title "Vibration Gs $MAX"
