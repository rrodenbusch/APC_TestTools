#!/usr/bin/perl
#################################################
#
#
#   i2c_interface.pl
#
#
#   4/8/18 		First release
#				Added ability to get mac address for reporting
#
#################################################
use lib "$ENV{HOME}/RPi";
use warnings;
use strict;
use Time::HiRes;
use MCP23008;

my $PollInterval = 5;
$PollInterval = $ARGV[1] if defined($ARGV[1]);

my $deviceAddress = 0x20;

my $device = MCP23008->new($deviceAddress);
my (@bytes_read, $value, $bufstr);

sub getMACaddress {
	my $resp = `/sbin/ifconfig eth0 | head -1`;
	$resp =~ s/\R//g;
	my @fields = split(' ',$resp);
	my $mac = $fields[4];
	return($mac);
}

sub getRouterMACaddress {
	my $resp = `sudo nmap -p 80 192.168.0.1 |grep MAC`;
	$resp =~ s/\R//g;
	my @fields = split(' ',$resp);
	my $mac = $fields[2];
	return($mac);
}

my $myMAC = getMACaddress();
my $routerMAC = getRouterMACaddress();
my $UID = "$routerMAC::$myMAC";
$UID =~ s/://g;
print "Found MAC: $myMAC\nRouter: $routerMAC\n";


1;

