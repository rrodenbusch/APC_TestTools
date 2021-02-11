#!/bin/bash
cd $HOME
$HOME/APC_TestTools/scourPower.pl >>scour.log 2>&1
/usr/bin/rsync -r $HOME/B827EB* mthinx@$1:/extdata/power 2>&1 >>scour.log

