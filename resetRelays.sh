#!/bin/bash
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x0A 0x00
/home/pi/APC_TestTools/I2Cio.pl write 0x22 0x00 0xFF
gpio -g write 18 0
gpio -g mode 18 in
gpio -g write 23 0
gpio -g mode 23 in
gpio -g write 23 0
gpio -g mode 23 in
gpio -g write 24 0
gpio -g mode 24 in
gpio -g write 25 0
gpio -g mode 25 in
gpio -g write 12 0
gpio -g mode 12 in
gpio -g write 13 0
gpio -g mode 13 in
gpio -g write 16 0
gpio -g mode 16 in
gpio -g write 19 0
gpio -g mode 19 in
gpio -g write 20 0
gpio -g mode 20 in
gpio -g write 26 0
gpio -g mode 26 in

