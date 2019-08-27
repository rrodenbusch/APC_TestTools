#!/bin/bash

while [ 1 ]; do
   gpio -g write 19 1
   gpio -g write 26 1
   gpio -g write 16 1
   gpio -g mode 19 out
   gpio -g mode 26 out
   gpio -g mode 16 out
   sleep 1
done;

