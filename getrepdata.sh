#!/bin/bash

usage () {
   NEW=$'\n'
   u="Usage:  getrepdata.sh${NEW}"
   u="$u          -d (--doors)${NEW}"
   u="$u          -c (--counts)${NEW}"
   u="$u          -C (--details${NEW}"
   u="$u          -D (--date)${NEW}"
   u="$u          -p (--portal)${NEW}"
   u="$u          -t (--trip)${NEW}"

   echo "$u";
}

BASEDIR=/home/ubuntu/MBTA/Working
PORTALBASE=/home/ubuntu/MBTA/Consist

if [[ -z "$1" ]] ;
then
   DEFAULT=1
fi
while [ "$1" != "" ]; do
    case $1 in
        -d | --door )           #shift
                                echo "Retrieve Doors"
                                DOORS=1
                                ;;
        -f | --force )           #shift
                                echo "Retrieve Doors"
                                FORCE=1
                                ;;
        -c | --counts )         #shift
                                echo "Retrieve Counts"
                                COUNTS=1
                                ;;
        -C | --details )        #shift
                                echo "Retrieve Details"
                                DETAILS=1
                                ;;
        -T | --onlyTrip )       shift
                                echo "Retrieve Trips"
                                ONLYTRIP=$1
                                ;;
        -p | --portal )         #shift
                                echo "Retrieve Portal"
                                PORTAL=1
                                ;;
        -t | --trips )          #shift
                                echo "Retrieve Trips"
                                TRIPS=1
                                ;;
        -D | --date )           shift
                                DATE=$1
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

WORKDIR=$BASEDIR/$DATE
PORTALDIR=$PORTALBASE/$DATE
LOCALDIR=$HOME/MBTA/Working/$DATE

echo "Retrieve data from $DATE to $LOCALDIR [Y/n] ?"
[[ -n $FORCE ]] || read var
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit

cd $HOME/MBTA/Working
[[ -d $DATE ]] || mkdir $DATE
cd $DATE
WDIR=`pwd` && echo "Working in $WDIR"

[[ -n $PORTAL ]]   && `rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/$PORTALDIR/* .`
[[ -n $COUNTS ]]   && `rsync -e "ssh -i ~/PEM/richard-processing.pem"ubuntu@mbta-temp-flowz-server.mthinx.com:/$PORTALDIR/*PeopleCounts* .`
[[ -n $DETAILS ]]  && `rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/$WORKDIR/*CountDetail* .`
[[ -n $DOORS ]]    && `rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/$WORKDIR/*DoorData* .`

[[ -n $TRIPS ]]    && `rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/$WORKDIR/*CoachTrip* .`
[[ -n $TRIPS ]]    && `rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/$WORKDIR/*TripCoach* .`
[[ -n $ONLYTRIP ]] && `rsync -e "ssh -i ~/PEM/richard-processing.pem" ubuntu@mbta-temp-flowz-server.mthinx.com:/$WORKDIR/T$ONLYTRIP* .`


exit

ls -ltr
