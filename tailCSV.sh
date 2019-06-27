#!/bin/bash
FNAME=`ls -Art *.csv | tail -n 1`
tail -f $FNAME

