#!/bin/bash

[ -z $1 ] && echo 'retrySSH.sh user IP "cmd"' && exit 1
[ -z $2 ] && echo 'retrySSH.sh user IP "cmd"' && exit 1
while [ 1 ]; do
   fping -c 1 -t 200 -4 $2
   if [ "$?" == 0 ]; then
       ssh $1@$2  "$3"
       [ "$?" == "0" ] && echo "Success" && sleep 1 && ssh $1@$2
   fi
   sleep 1
done

