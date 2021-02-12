#!/bin/bash
echo "Wdog timer reboot in 60 PID:$$"
sleep 60
echo "Wdog timer reboot in 10"
sleep 5
echo "Wdog timer reboot in 5"
sleep 5
sudo shutdown -r now

