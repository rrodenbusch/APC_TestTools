#!/usr/bin/perl
use strict;
use warnings;
my $device = $ARGV[0];

die "Only configured for wlan0 or wlan1" unless ($device eq "wlan0") or ($device eq "wlan1");
my $resp = `route -n >routes.txt`;
open (my $fh, "routes.txt") or die "Unable to open routes.txt \n$!\n";
my $line = <$fh>;
$line  = <$fh>;
$line = <$fh>;
$line =~ s/\R//g;
my @flds = split(' ',$line);
if ($flds[7] ne $device) {
   $resp = `sudo route add default gw 192.168.0.1 dev $device`;
}

print "Done";
1;

