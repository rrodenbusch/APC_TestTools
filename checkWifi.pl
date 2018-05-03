#!/usr/bin/perl
use strict;
use warnings;

sub pi_ping{
	my $host = shift;
	my $cnt = `sudo ping -c 1 $host |grep icmp |wc -l`;
	return($cnt);
}

print "Google here\n" if pi_ping("8.8.8.8");
print "yahoo here\n" if pi_ping("yahoo.com");
print "vpn here\n" if pi_ping("10.50.0.1");

print "test\n" if pi_ping("8.8.8.2"); 

1;
