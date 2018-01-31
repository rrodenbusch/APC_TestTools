#!/bin/bash
echo $1
sudo iwlist $1 scan |grep Frequency |sort |uniq -c|sort -n

