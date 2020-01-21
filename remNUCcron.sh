#!/bin/bash
while [ 1 ]; do
   ssh mthinx@192.168.0.$1 'crontab -r'
   sleep 1
done

