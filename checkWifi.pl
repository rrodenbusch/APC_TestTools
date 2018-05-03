#!/usr/bin/perl
use strict;
use warnings;

my $device = $ARGV[0];

sub pi_ping{
	my $host = shift;
	my $cnt = `sudo ping -c 1 $host |grep icmp |wc -l`;
	return($cnt);
}

my $network = pi_ping("8.8.8.8");
my $naming = pi_ping("yahoo.com");
print "Checking network connection\n";
if ($network > 0) {
	print "Network OK\n";
} else {
	print "No network found\n";
	print "Resetting $device\n";
	`sudo ifdown $device`;
	sleep(5);
	`sudo ifup $device`;
	sleep(5);
	$network = pi_ping("8.8.8.8");
	$naming = pi_ping("yahoo.com");
	print "Results  Network: $network   Naming: $naming\n";
}

1;
