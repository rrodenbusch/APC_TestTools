#!/bin/bash

[ -z $1 ] && echo 'retrySSH.sh user@IP "cmd"' && exit 1
while [ 1 ]; do
   ssh $1  "$2"
   [ "$?" == "0" ] && echo "Success" && sleep 1 && ssh $1
   sleep 1
done

