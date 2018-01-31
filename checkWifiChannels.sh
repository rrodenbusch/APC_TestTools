#!/bin/bash
sudo iwlist $1 scan |grep Frequency |sort |uniq -c|sort -n
	