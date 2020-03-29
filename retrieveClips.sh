#!/bin/bash
if [[ -z "$1" || -z "$2" || -z "$3" ]] ;
then
   echo "Usage:  retrieveClips.sh Coach VPN yyyymmdd"
   exit
fi
COACH=$1
VPN=$2
DATE=$3
SCRIPTNAME=$COACH.CoachClips.$DATE.sh
BASEDIR=$HOME/MBTA/Working
CLIPDIR=$BASEDIR/clips
WORKDIR=$CLIPDIR/$DATE
REMTARGDIR=/data/NVR/clips/$DATE

echo "Build and Retrieve clips from $COACH $DATE at $VPN? [Y/n] ?"
read var
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit
echo "##         Create local dir"
cd $BASEDIR
WDIR=`pwd` && echo "Working in $WDIR"
[[ -d $DATE ]]  || mkdir $DATE
cd $DATE
[[ -d clips ]] || mkdir clips
cd clips
[[ -d $COACH ]] || mkdir $COACH
cd $COACH
WDIR=`pwd` && echo "Working in $WDIR"
cp -f $BASEDIR/$DATE/clips/$SCRIPTNAME .
echo "###        Copying $SCRIPTNAME to $COACH at 10.50.$VPN"
scp $SCRIPTNAME pi@10.50.$VPN:/data/NVR
REMCMD="cd /data/NVR/Working | /data/NVR/$SCRIPTNAME f | ls -ltr $REMTARGDIR"
echo "####      Executing $REMCMD  @ $10.50.$VPN"
ssh pi@10.50.$VPN $REMCMD
echo "#####     Copying clips back"
scp pi@10.50.$VPN:/$REMTARGDIR/* .
echo "Copy Complete"
ls -ltr
