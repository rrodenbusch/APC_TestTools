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
   DATE=`date +%Y%m%d`
fi
TARGET=mthinx@10.50.$TARGIP


cd $HOME/MBTA/Working
[[ -d $DATE ]]  || mkdir $DATE
cd $DATE
[[ -d clips ]]  || mkdir clips
cd clips
[[ -d $COACH ]]  || mkdir $COACH
cd $COACH
WDIR=`pwd` && echo "Working in $WDIR"
cd $HOME/MBTA/Working

echo "Push $COACH clips to $TARGET:$TARGDIR? [Y/n] ?"
[[ -n $FORCE ]] || read var
echo "Begin"
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit

WDIR=`pwd` && echo "Working in $WDIR"
echo "###        Copying clips"
ssh $TARGET mkdir -p $TARGDIR/$DATE/clips/$COACH
rsync -rva ./$DATE/clips/$COACH/* $TARGET:$TARGDIR/$DATE/clips/$COACH >>$LOGPREFIX.log 2>&1
echo "Sync of $COACH to $TARGET:$TARGDIR Complete"
