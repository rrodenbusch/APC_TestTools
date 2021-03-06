#!/bin/bash

usage () {
   NEW=$'\n'
   u="Usage:  syncClips.sh${NEW}"
   u="$u          -c (--coach)${NEW}"
   u="$u          -d (--date)${NEW}"
   u="$u          -f (--force)${NEW}"
   u="$u          -t (--target)${NEW}"
   u="$u          -D (--basedir)${NEW}"
   echo "$u";
}

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
                                BASEDIR=$1
                                ;;
        -t | --target)          shift
                                TARGET=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
if [[ -z $DATE ]] ;
then
   DATE=`date +%Y%m%d`
fi
if [[ -z $BASEDIR ]] ;
then
   BASEDIR=$HOME/MBTA/Working
fi
if [[ -z $TARGET ]] ;
then
   TARGET=mthinx@192.168.1.140
fi

cd $BASEDIR
[[ -d $DATE ]]  || mkdir $DATE
cd $DATE
CLIPDIR=$BASEDIR/$DATE/clips
REMTARGDIR=/data/Videos/$DATE

if [[ -n $COACH ]] ;
then
   CLIPDIR=$CLIPDIR/$COACH
   REMTARGDIR=$REMTARGDIR/$COACH
fi

echo "SyncClips from local $CLIPDIR to $TARGET:$REMTARGDIR? [Y/n] ?"
[[ -n $FORCE ]] || read var
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit
cd $CLIPDIR
WDIR=`pwd` && echo "Working in $WDIR"
LDATE=`date "+%Y%m%d %T"`
echo "$LDATE syncClips $CLIPDIR to $TARGET:$REMTARGDIR Starting"
rsync -rva $CLIPDIR/* $TARGET:$REMTARGDIR
echo "Copy Complete"
LDATE=`date "+%Y%m%d %T"`
echo "$LDATE syncClips $CLIPDIR to $TARGET:$REMTARGDIR Completed"
