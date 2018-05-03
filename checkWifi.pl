#!/usr/bin/perl
use strict;
use warnings;

use Net::Ping;

my $p = Net::Ping->new();

print "Google here" if $p->ping("8.8.8.8");
print "VPN here" if $p->ping("10.50.0.1");


1;
