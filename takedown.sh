#!/bin/bash
#####################################################################
#
#   takedown.sh
#
#   sits and waits for the server to come online
#     then imediately kills the cron, disables fire and reboots
#
#   outputs to ~/takedown.log
#
#####################################################################
usage () {
   NEW=$'\n'
   u="Usage:  takedown.sh${NEW}"
   u="$u          -p (--pi)  IP for the target (221,222)${NEW}"
   u="$u          -n (--mthinx) IP for the target${NEW}"
   echo "$u";
}


while [ "$1" != "" ]; do
    case $1 in
        -p | --pi )             shift
                                USER='pi'
                                IP=$1
                                ;;
        -n | --nuc )           shift
                                USER='mthinx'
                                IP=$1
                                ;;
 
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done
[ -z $IP ]   && echo usage && exit 1
[ -z $USER ] && echo usage && exit 1
[ "$PARTS" == "2" ] &&  IP="192.$1";
[ "$PARTS" == "1" ] &&  IP="192.168.$1";
[ "$PARTS" == "0" ] &&  IP="192.168.0.$1";
$HOME/APC_TestTools/retrySSH.sh $USER $IP "crontab -r;sudo systemctl disable fire;sudo shutdown -r now" >>$HOME/takedown.log
ERR="$?"

exit "$ERR"