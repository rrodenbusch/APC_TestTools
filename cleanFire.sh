#!/bin/bash
sudo service fire stop
sudo rm /var/fire/config/openvpn/*
sudo rm /var/fire/config/*
sudo systemctl stop fbd-doortemp
sudo systemctl stop fbd-sound
sudo systemctl stop fbd-mpu
sudo systemctl disable fbd-doortemp
sudo systemctl disable fbd-mpu
sudo systemctl disable fbd-sound
