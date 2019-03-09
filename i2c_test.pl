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
use Ard_APC;

my $PollInterval = 5;
$PollInterval = $ARGV[1] if defined($ARGV[1]);

my $expectedVersion = 8;
my $deviceAddress = 0x08;

my $device = Ard_APC->new($deviceAddress);
my (@bytes_read, $value, $bufstr);
my %Ardmodes = (
	'L' => 'Low Battery',
	'S' => 'Startup',
	'R' => 'Running'
	);
	


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

my ($version,$cnt) = $device->getVersion();
my ($temp,$doors, $GPSseconds,$epoch,@lines);
my ($prevLine,$prevFile) = (0,0);
my $outLine = '';
my $prevdoor = -1;
$prevFile = time();
my ($snd1Min,$snd1Max,$snd1Avg,$snd1Tot,$snd1Cnt) = (9999,-9999,-1,0,0);
my ($snd2Min,$snd2Max,$snd2Avg,$snd2Tot,$snd2Cnt) = (9999,-9999,-1,0,0);
my $resp = $device->getData();
print "$resp\n";

while (1) {
	$GPSseconds = -1;
	$epoch = time();
	($doors,$cnt) = $device->getDoors();
	if ($epoch - $prevLine > $PollInterval) {
		# output at a polling interval
		$prevLine = $epoch;
		$prevdoor = $doors;
		($temp,$cnt) = $device->getTemp();
		$snd1Avg = -999;
		$snd1Avg = $snd1Tot/$snd1Cnt if ($snd1Cnt > 0);
		$snd2Avg = -999;
		$snd2Avg = $snd2Tot/$snd2Cnt if ($snd2Cnt > 0);
		my $line = "$UID,$epoch,$GPSseconds,$doors,$temp,$snd1Avg,$snd1Max,$snd2Avg,$snd2Max";
		($snd1Tot,$snd1Cnt,$snd2Tot,$snd2Cnt) = (0,0,0,0);
		($snd1Max,$snd1Min,$snd2Max,$snd2Min) = (-999,999,-999,999);
		print "$line\n";
	} elsif ( ( !defined($doors) ) || ($doors == -1) ) {
		print "$UID,$epoch,DoorError\n";
	} else {
                #$doors != $prevdoor) {
		# output any change of states in the doors
		$snd1Avg = -999;
		$snd1Avg = $snd1Tot/$snd1Cnt if ($snd1Cnt > 0);
		$snd2Avg = -999;
		$snd2Avg = $snd2Tot/$snd2Cnt if ($snd2Cnt > 0);
		my $line = "$UID,$epoch,$GPSseconds,$doors,$temp,$snd1Avg,$snd1Max,$snd2Avg,$snd2Max";
		$prevdoor = $doors;
		print "$line\n";
	}
	my $curSnd1 = $device->getSound1();
	my $curSnd2 = $device->getSound2(); 
	$snd1Tot += $curSnd1;
	$snd2Tot += $curSnd2;
	$snd1Cnt++;
	$snd2Cnt++;
	$snd1Max = $curSnd1 if ($curSnd1 > $snd1Max);
	$snd2Max = $curSnd2 if ($curSnd2 > $snd2Max);
        sleep (1);
	Time::HiRes::sleep(0.05);
}

1;
