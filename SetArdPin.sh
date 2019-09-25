#!/bin/bash
/home/pi/APC_TestTools/I2Cio.pl write0 0x0A 0x70  $1
/home/pi/APC_TestTools/I2Cio.pl write0 0x0A 0x71  $2
/home/pi/APC_TestTools/I2Cio.pl write0 0x0A 0x72 0xE1
/home/pi/APC_TestTools/I2Cio.pl write0 0x0A 0x73 0xE1
/home/pi/APC_TestTools/I2Cio.pl write0 0x0A 0x74 0x47

