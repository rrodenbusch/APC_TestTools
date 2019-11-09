#!/bin/bash
echo "Setup the VISUDO"
sudo visudo
if [ -e /var/lib/dpkg/lock-frontend ];
then
   sudo rm /var/lib/dpkg/lock-frontend
fi
if [ -e /var/lib/dpkg/lock ];
then
   sudo rm /var/lib/dpkg/lock
fi
echo "Install git"
sudo apt-get install git
echo "Updated repositories"
if [ ! -d /home/mthinx/NUC ]; then
   cd /home/mthinx
   git clone https://github.com/rrodenbusch/NUC
fi
cd /home/mthinx/NUC
git pull origin master
if [ ! -d /home/mthinx/APC_TestTools ]; then
   cd /home/mthinx
   git clone https://github.com/rrodenbusch/APC_TestTools
fi
cd /home/mthinx/APC_TestTools
git pull origin master

cp /home/mthinx/NUC/authorized_keys ~/.ssh

if  ! grep "APC_TestTools" ~/.bashrc 
then
   echo ' ' >>~/.bashrc
   echo 'export PATH=$PATH:/home/mthinx/APC_TestTools' >>~/.bashrc
   echo ' ' >>~/.bashrc
fi

