#!/bin/bash
if [ -z "$1" ] 
then
   FPATH="*.csv"
else
   FPATH="$1/*.csv"
fi
FNAME=`ls -Art $FPATH | tail -n 1`
echo $FNAME
tail -f $FNAME
