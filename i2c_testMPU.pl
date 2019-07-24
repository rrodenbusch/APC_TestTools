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
use lib "$ENV{HOME}/APC_TestTools";
use warnings;
use strict;
use Time::HiRes;
use MPU6050;

my $deviceAddress = 0x68;
my $device = MPU6050->new($deviceAddress);
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


#my $myMAC = getMACaddress();
#my $routerMAC = getRouterMACaddress();
#my $UID = "$routerMAC::$myMAC";
#$UID =~ s/://g;
#print "Found MAC: $myMAC\nRouter: $routerMAC\n";
my $maxG = 2;
$maxG = $ARGV[0] if (defined($ARGV[0]));
my $cal = 1.0;
$cal = $ARGV[1] if (defined($ARGV[1]));
my $maxG=`grep maxG /home/pi/RPi/config.ini`;
my @fields=split('=',$maxG) if (defined($maxG));
$maxG=$fields[1] if ($fields[0] eq 'maxG');
$device->wakeMPU($maxG);
print "Waking MPU at maxG = $maxG\n";
sleep(3);

while (1) {
	my ($epoch,$msec) = Time::HiRes::gettimeofday();
	my ($AcX,$AcY,$AcZ) = $device->readAccelG();
	my ($tmp,$tmpC,$tmpF) = $device->readTemp();
        $AcX *= $cal;
        $AcY *= $cal;
        $AcZ *= $cal;
        my $totG = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
	my $line= join(',',($epoch,$msec,$totG,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF));
	print "$line\n";
	sleep(0); 
	#Time::HiRes::sleep(0.333);
}

1;
