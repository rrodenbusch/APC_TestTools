#!/bin/bash
declare -A COACHDEF
declare -A DEFAULTS
declare -A TARGETS
declare -a TEAM

TEAM=( Carlos Don Jacob Patrick Sandra )

COACHDEF[Carlos]=' -c 618,248,240 '
DEFAULT[Carlos]='-t 5.40 -D /data/Videos/ -f -l Carlos'

COACHDEF[Don]=' -c 1811,1804 ' 
DEFAULTS[Don]='-t 5.11 -D /data/Videos/ -f -l Don'

COACHDEF[Jacob]=' -c 846,808,767 '
DEFAULTS[Jacob]='-t 5.78 -D /data/Videos/ -f -l Jacob'

COACHDEF[Patrick]=' -c 610,204 '
DEFAULTS[Patrick]='-t 5.28 -D /data/Videos/ -f -l Patrick'

COACHDEF[Sandra]=' -c 767,254 '
DEFAULTS[Sandra]='-t 5.77 -D /data/Videos/ -f -l Sandra'

usage () {
   NEW=$'\n'
   u="Usage:  retrieveClips.sh${NEW}"
   u="$u          -c (--coaches [csv])${NEW}"
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
   [[ -n ${TARGETS[$TARG]} ]] && `/home/mthinx/APC_TestTools/pushClips.sh ${COACHDEF[$TARG]} ${DEFAULTS[$TARG]}`
done
