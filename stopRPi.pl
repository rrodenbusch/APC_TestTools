#!/usr/bin/perl
use strict;
use warnings;

my @pidList;
my @ProcList = ('SystemMonitor.pl','MapNetwork.pl','WatchDog.pl','ConfigServer.pl','ShutdownNUC.pl','i2c_apc_v6.pl',
				'RemoteLog.pl', 'RunNVR.pl', 'RemoteData.pl','WatchSSD.pl','i2c_apc_v6.pl','Watcher.pl','WatchRPi.pl');
my $ret = `ps -elf |grep perl`;
print $ret;
foreach my $curProc (@ProcList) {
	my $return = `ps -C $curProc -o pid`;
 	my @lines = split("\n",$return);
 	my $pid = -1;
 	if ( scalar @lines > 1) {
		my @fields = split(" ",$lines[0]);
 		$pid = $lines[1];
 		$pid =~ s/ //g;	
 	}
	push(@pidList,$pid) unless $pid == -1;
}
if (scalar @pidList > 0) {
	my $cmd = "kill " . join(" ",@pidList);
	`$cmd`;	
}
$ret = `ps -elf |grep perl`;
print $ret;

1;
