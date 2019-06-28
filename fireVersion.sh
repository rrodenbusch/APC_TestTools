#!/bin/bash
FIREW=`cat /opt/firewatchdog/version.txt`
grep app.version  /opt/fire/Base.properties
echo watchdog.version=$FIREW

