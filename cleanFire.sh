#!/bin/bash
sudo service fire stop
sudo rm -r /var/fire/config/openvpn/*
sudo rmdir /var/fire/config/openvpn
sudo rm -r /var/fire/config/*
sudo systemctl stop fbd-doortemp
sudo systemctl stop fbd-sound
sudo systemctl stop fbd-mpu
sudo systemctl disable fbd-doortemp
sudo systemctl disable fbd-mpu
sudo systemctl disable fbd-sound
sudo rm /etc/systemd/system/fbd-*

