#!/bin/bash
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
        -h | --help )           echo "Usage:  retrieveClips.sh -c {Coach} -d {yyyymmdd} -v {video dir [~/MBTA/Working]}"
                                exit
                                ;;
        * )                     echo "Usage:  retrieveClips.sh -c {Coach} -d {yyyymmdd} -v {video dir [~/MBTA/Working]}"
                                exit 1
    esac
    shift
done

if [[ -z $VDIR ]] ;
then
   VDIR="$HOME/MBTA/Working"
fi
FLIST="$COACH.CoachClips.$DATE.sh"
if [[ -z $DATE ]] ;
then
   DATE=`date +%Y%m%d`
fi
FLIST="$COACH.CoachClips.$DATE.sh"
if [[ -z $COACH ]] ;
then
   FLIST="*.CoachClips.$DATE.sh"
fi
cd $VDIR
[[ -d clips ]] || mkdir clips
cd clips
[[ -d $DATE ]] || mkdir $DATE
cd $DATE
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/TripCoaches.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/CoachTrips.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/DoorEventData.$DATE.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/*.PeopleCounts$DATE.csv .`
`rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/$FLIST .`
echo "Copy Complete"
[[ -z QUIET ]] && ls -ltr
exit 0
