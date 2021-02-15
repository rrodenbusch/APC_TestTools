#!/usr/bin/perl
use strict;
use warnings;


my @pidList;
my @ProcList = ('SystemMonitor.pl','MapNetwork.pl','WatchDog.pl','ConfigServer.pl','ShutdownNUC.pl','i2c_apc_v6.pl',
				    'RemoteLog.pl', 'RunNVR.pl', 'RemoteData.pl','WatchSSD.pl','i2c_apc_v6.pl','Watcher.pl','WatchRPi.pl','i2c_fbd.pl');
my $ret0 = `ps -elf |grep perl` ;
print "\nBEFORE:\n$ret0\n";
foreach my $curProc (@ProcList) {
	my $return = `ps -eo pid,command |grep $curProc |grep -v grep`;
 	my @lines = split("\n",$return);
 	my $pid = -1;
 	if ( scalar @lines > 1) {
		my @fields = split(" ",$lines[0]);
		my $proc = pop(@fields);
 		$pid = $lines[1];
 		$pid =~ s/ //g;	
 	}
	push(@pidList,$pid) unless $pid == -1;
}
$ret0 = `ps -eopid,command |grep openRTSP |grep -v grep`;
print "$ret0\n";

if ( (scalar @pidList > 0) && defined($ARGV[0]) && ($ARGV[0] eq 'kill')) {
	my $cmd = "kill " . join(" ",@pidList);
	`$cmd`;	
	my $ret1 = `ps -elf |grep perl`;
	print "\nAFTER:\n$ret1\n";
} elsif (defined($ARGV[0])) {
   my $return = `ps -eo pid,command |grep $ARGV[0] |grep -v grep`;
   my @lines = split("\n",$return);
   foreach my $curLine (@lines) {
      my ($pid,$proc) = split(" ",$curLine);
      $pid =~ s/ //g;
      `kill $pid`;
   }
}


1;
