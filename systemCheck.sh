#!/bin/bash

usage () {
   NEW=$'\n'
   u="Usage:  systemCheck.sh${NEW}"
   u="$u          -c (--coach)${NEW}"
   u="$u          -f (--force)${NEW}"
   u="$u          -P{11|12|21|22|32}${NEW}"
   u="$u          -r (--rlog)${NEW}"
   u="$u          -V (--vpn)${NEW}"
   echo "$u";
}

die () {
   echo "$*" 2>&2;
   exit 1;
}

while [ "$1" != "" ]; do
    case $1 in
        -c | --coach )          shift
                                COACH=$1
                                ;;
        -f | --force )           #shift
                                FORCE=1
                                ;;
        -P | --Pi )             shift
                                OPT="-P $1"
                                ;;
        -v | --vpn )            shift
                                VAR=$1
                                VPN="10.50.$VAR"
                                ;;
        -r | --rlog )           #shift
                                OPT="-r"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
if [[ ! `ping -n 1 10.50.0.1` ]] ;
then
   die "VPN OFFLINE"
fi
if [[ -z $VPN ]] ;
then
   VPN=`$HOME/APC_TestTools/findVPN.pl -c $COACH $OPT | awk '{print $2}'`
fi
[[ -z $VPN ]] && die "$COACH VPN not found"
echo "Found $VPN"
PING=`ping -n 1 $VPN |Findstr /I /C:"timed out" /C:"host unreachable" /C:"could not find host"`
[[ ! $PING  ]] || die "$VPN OFFLINE"
echo "Run system check on $COACH at $VPN? [Y/n]"
[[ -n $FORCE ]] || read var
[[ $var == 'Y' || $var  == 'y' || $var = '' ]] || exit
LDATE=`date "+%Y%m%d %T"` 
echo "$LDATE,systemCheck.sh,Begin,$COACH,$VPN"
ssh pi@$VPN 'cd /home/pi/APC_TestTools/; git pull origin master'
ssh pi@$VPN 'cd /home/pi;/home/pi/APC_TestTools/systemCheck.pl $OPT'
LDATE=`date "+%Y%m%d %T"` 
echo "$LDATE,systemCheck,Complete,$COACH,$VPN"
