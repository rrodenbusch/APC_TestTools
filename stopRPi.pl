#!/usr/bin/perl
use strict;
use warnings;


my $pid;
my @pidList;
my @ProcList = ('SystemMonitor.pl','MapNetwork.pl','WatchDog.pl','ConfigServer.pl','ShutdownNUC.pl','i2c_apc_v6.pl',
				'RemoteLog.pl', 'RunNVR.pl', 'RemoteData.pl','WatchSSD.pl','i2c_apc_v6.pl','Watcher.pl');
				
foreach my $curProc (@ProcList) {
	$pid = `ps -C $curProc -o pid`;
	push(@pidList,$pid);
}
my $cmd = "kill " . join(",",@pidList);
`$cmd`;

1;
