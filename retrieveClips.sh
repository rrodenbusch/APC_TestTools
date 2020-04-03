#!/bin/bash
while [ "$1" != "" ]; do
    case $1 in
        -c | --coach )          shift
                                COACH=$1
                                ;;
        -f | --force )          
                                FORCE=1
                                ;;
        -v | --vpn )            shift
                                VAR=$1
                                VPN="10.50.$VAR"
                                ;;
        -d | --date )           shift
                                DATE=$1
                                ;;
        -D | --dir )            shift
                                BASEDIR=$1
                                ;;
        -h | --help )           echo "Usage:  retrieveClips.sh -f(force) -c Coach -d {yyyymmdd} -v {VPN} -V VideoDir"
                                exit
                                ;;
        * )                     echo "Usage:  retrieveClips.sh -f(force) -c Coach -d {yyyymmdd} -v {VPN} -V VideoDir"
                                exit 1
    esac
    shift
done
if [[ -z $DATE ]] ;
then
   DATE=`date +%Y%m%d`
fi
if [[ -z $VPN ]];
then
   VPN=`findVPN.pl -c $COACH -r | awk  '{print $2}'`
fi
SCRIPTNAME=$COACH.CoachClips.$DATE.sh
if [[ -z $BASEDIR ]] ;
then
   BASEDIR=$HOME/MBTA/Working
fi
CLIPDIR=$BASEDIR/clips
WORKDIR=$CLIPDIR/$DATE
REMTARGDIR=/data/NVR/clips/$DATE

echo "Build and Retrieve clips from $COACH $DATE at $VPN? [Y/n] ?"
[[ -n $FORCE ]] || read var
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit
ssh pi@$VPN "/home/pi/APC_TestTools/gitAll"
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
echo "###        Copying $SCRIPTNAME to $COACH at $VPN"
rsync $SCRIPTNAME pi@$VPN:/data/NVR
REMCMD="rm -r $REMTARGDIR/*;cd /data/NVR/Working; /data/NVR/$SCRIPTNAME f ; ls -ltr $REMTARGDIR"
echo "####      Executing $REMCMD  @ $VPN"
ssh pi@$VPN $REMCMD
echo "#####     Copying clips back"
rsync pi@$VPN:/$REMTARGDIR/* .
echo "Copy Complete"
ls -ltr
