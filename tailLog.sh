#!/bin/bash
FNAME=`ls -Art *.log | tail -n 1`
tail -f $FNAME

