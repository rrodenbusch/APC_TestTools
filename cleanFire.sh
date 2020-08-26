#!/bin/bash
sudo service fire stop
sudo rm -r /var/fire/config/openvpn/*
sudo rmdir /var/fire/config/openvpn
sudo rm -r /var/fire/config/*
cd /var/fire
rm -r *
sudo ls -ltr /var/fire/config/openvpn
sudo ls -ltr /var/fire/config

