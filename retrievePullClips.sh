#!/bin/bash
while [ "$1" != "" ]; do
    case $1 in
        -c | --coach )          shift
                                COACH=$1
                                ;;
        -d | --date )           shift
                                DATE=$1
                                ;;
        -h | --help )           echo "Usage:  retrieveClips.sh -c Coach -d {yyyymmdd} -v {VPN}"
                                exit
                                ;;
        * )                     echo "Usage:  retrieveClips.sh -c Coach -d {yyyymmdd} -v {VPN}"
                                exit 1
    esac
    shift
done
if [[ -z $DATE ]] ;
then
   DATE=`date +%Y%m%d`
fi
FLIST="$COACH.CoachClips.$DATE.sh"
if [[ -z $COACH ]] ;
then
   FLIST="*.CoachClips.$DATE.sh"
fi
cd ~/MBTA/Working
[[ -d $DATE ]] || mkdir $DATE
cd $DATE
[[ -d clips ]] || mkdir clips
cd clips
FCMD="scp -i ~/PEM/richard-processing.pem ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/$FLIST ."
echo "$FCMD"
`scp -i ~/PEM/richard-processing.pem ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/TripCoaches.csv .`
`scp -i ~/PEM/richard-processing.pem ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/CoachTrips.csv .`
`scp -i ~/PEM/richard-processing.pem ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/DoorEventData.$DATE.csv .`
`scp -i ~/PEM/richard-processing.pem ubuntu@mbta-temp-flowz-server.mthinx.com:/home/ubuntu/MBTA/Working/$DATE/*.PeopleCounts$DATE.csv .`
`$FCMD`
echo "Copy Complete"
ls -ltr
