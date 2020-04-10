#!/bin/bash


usage () {
   NEW=$'\n'
   u="Usage:  retrieveClips.sh${NEW}"
   u="$u          -c (--coach)${NEW}"
   u="$u          -d (--date)${NEW}"
   u="$u          -v (--video) [MBTA/Working]${NEW}"
   u="$u          -q (--quiet)${NEW}"
   echo "$u";
}

while [ "$1" != "" ]; do
    case $1 in
        -c | --coach )          shift
                                COACH=$1
                                ;;
        -v | --video )          shift
                                VDIR=$1
                                ;;
        -d | --date )           shift
                                DATE=$1
                                ;;
        -q | --quiet )          # shift
                                QUIET=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [[ -z $VDIR ]] ;
then
   VDIR="$HOME/MBTA/Working"
fi
if [[ -z $DATE ]] ;
then
   DATE=`date +%Y%m%d`
fi
FLIST="$COACH.CoachClips.$DATE.sh"
if [[ -z $COACH ]] ;
then
   FLIST="\*.CoachClips.$DATE.sh"
fi
cd $VDIR
[[ -d $DATE ]] || mkdir $DATE
cd $DATE
[[ -d clips ]] || mkdir clips
cd clips
[[ -f scripts ]] &&  rm scripts
[[ -d scripts ]] || mkdir scripts
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/TripCoaches.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/CoachTrips.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/DoorEventData.$DATE.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/*.PeopleCounts*.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/*.CoachClips.$DATE.sh ./scripts`
echo "Copy Complete"
[[ -z QUIET ]] && ls -ltr
LDATE=`date "+%Y%m%d %T"`
echo "$LDATE retrievePullClips $DATEcomplete"
exit 0