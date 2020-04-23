#!/bin/bash
declare -A COACHDEF
declare -A DEFAULTS
declare -A TARGETS
declare -a TEAM


DATE=`date +%Y%m%d`

source /home/mthinx/APC_TestTools/teams.ini

usage () {
   NEW=$'\n'
   u="Usage:  retrieveClips.sh${NEW}"
   u="$u          -N (--name )${NEW}"
   u="$u          -c (--coaches [csv])${NEW}"
   u="$u          -d (--date [yyyymmdd])${NEW}"   
   u="$u          -C (--Carlos)${NEW}"
   u="$u          -D (--Don)${NEW}"
   u="$u          -J (--Jacob)${NEW}"
   u="$u          -P (--Patrick)${NEW}"
   u="$u          -S (--Sandra)${NEW}"
   u="$u          -v (--video) [MBTA/Working]${NEW}"
   u="$u          -q (--quiet)${NEW}"
   echo "$u";
}

while [ "$1" != "" ]; do
    case $1 in
        -c | --coaches )      shift
                              COACHES=$1
                              ;;    
        -N | --name )         shift
                              TARGETS[$1]=1;
                              ;;    
        -C | --Carlos )       #shift
                              TARGETS[Carlos]=1
                              ;;
        -D | --Don )          #shift
                              TARGETS[Don]=1
                              ;;
        -J | --Jacob )        #shift
                              TARGETS[Jacob]=1
                              ;;
        -P | --Patrick )      # shift
                              TARGETS[Patrick]=1
                              ;;
        -S | --Sandra )       # shift
                              TARGETS[Sandra]=1
                              ;;
        -h | --help )         usage
                              exit
                              ;;
        * )                   usage
                              exit 1
    esac
    shift
done
## Loop through each team member and sync to any selected ##
for TARG in "${TEAM[@]}" ;
do
   #CMD="/home/mthinx/APC_TestTools/pushClips.sh ${COACHDEF[$TARG]} ${DEFAULTS[$TARG]} >>/home/mthinx/MBTA/Working/Push$TARG.log 2>&1"
   #echo "Executing in Team: $CMD"
   [[ -n ${TARGETS[$TARG]} ]] && `/home/mthinx/APC_TestTools/pushClips.sh ${COACHDEF[$TARG]} ${DEFAULTS[$TARG]} >>/home/mthinx/MBTA/Working/Push$TARG.log 2>&1`
done
DATE=`date "+%Y%m%d %T"`
echo "$DATE pushTeam complete"

exit 0
