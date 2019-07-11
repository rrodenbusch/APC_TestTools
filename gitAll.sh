#!/bin/bash
if [ -d ~/updates/PiInstall ]
then
   echo "Update PiInstall"
   cd ~/updates/PiInstall
   git pull origin master
fi
if [ -d ~/updates/RPi ]
then
   echo "Update RPi"
   cd ~/updates/RPi
   git pull origin master
fi
if [ -d ~/APC_TestTools ]
then
   echo "Update APC_TestTools"
   cd ~/APC_TestTools
   git pull origin master
fi
if [ -d ~/Arduino ]
then
   echo "Update Arduino"
   cd ~/Arduiono
   git pull origin master
fi
if [ -d ~/updates/NUC ]
then
   echo "Update NU"
   cd /updates/NUC
   git pull origin master
fi
