#!/bin/bash

usage () {
   NEW=$'\n'
   u="Usage:  syncClips.sh${NEW}"
   u="$u          -c (--coach)${NEW}"
   u="$u          -d (--date)${NEW}"
   u="$u          -f (--force)${NEW}"
   u="$u          -t (--target)${NEW}"
   u="$u          -D (--target dir)${NEW}"
   echo "$u";
}
LOGPREFIX="pushClips"
while [ "$1" != "" ]; do
    case $1 in
        -c | --coach )          shift
                                COACH=$1
                                ;;
        -d | --date )           shift
                                DATE=$1
                                ;;
        -f | --force )          #shift
                                FORCE=1
                                ;;
        -D | --dir )            shift
                                TARGDIR=$1
                                ;;
        -t | --target)          shift
                                TARGIP=$1
                                ;;
        -l| --logprefix)        shift
                                LOGPREFIX=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
if [[ -z $COACH || -z $TARGIP ]] ;
then
   usage
   exit
fi
if [[ -z $DATE ]] ;
then
   DATE=`$HOME/APC_TestTools/getTripDate.pl`
fi
TARGET=mthinx@10.50.$TARGIP


cd $HOME/MBTA/Working
[[ -d $DATE ]]  || mkdir $DATE
cd $DATE
[[ -d clips ]]  || mkdir clips
cd clips
for CURCOACH in $(echo $COACH | sed "s/,/ /g")
do
   [[ -d $CURCOACH ]]  || mkdir $CURCOACH
done

cd $HOME/MBTA/Working
WDIR=`pwd` && echo "Working in $WDIR"
echo "Push $COACH clips to $TARGET:$TARGDIR? [Y/n] ?"
[[ -n $FORCE ]] || read var
echo "Begin"
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit

WDIR=`pwd` && echo "Working in $WDIR"

LDATE=`date "+%Y%m%d %T" `
echo "$LDATE pushclips push $COACH to $TARGET:$TARGDIR Starting"
for CURCOACH in $(echo $COACH | sed "s/,/ /g")
do
   LDATE=`date "+%Y%m%d %T"`
   echo "$LDATE pushclips push $CURCOACH to $TARGET:$TARGDIR Starting"
   ssh $TARGET mkdir -p $TARGDIR/$DATE/clips/$CURCOACH
   rsync -rva ./$DATE/clips/$CURCOACH/* $TARGET:$TARGDIR/$DATE/clips/$CURCOACH >>$LOGPREFIX.log 2>&1
   LDATE=`date "+%Y%m%d %T"`
   echo "$LDATE pushClips push $CURCOACH to $TARGET:$TARGDIR Complete"
done
echo "$LDATE pushClips push to $TARGET:$TARGDIR Complete"

exit 0