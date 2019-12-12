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
#use RPiConfig;
use MPU6050;

## Setup Signals
my %sig = ( HUP => 0, ABRT => 0, USR1 => 0, USR2 => 0, CONT => 0, QUIT => 0, STOP => 0, INT => 0 );
$SIG{HUP}  = sub {$sig{HUP} = 1};
$SIG{ABRT} = sub {$sig{ABRT} = 1};
$SIG{USR1} = sub {$sig{USR1} = 1};
$SIG{USR2} = sub {$sig{USR2} = 1};
$SIG{CONT} = sub {$sig{CONT} = 1};
$SIG{QUIT} = sub {$sig{QUIT} = 1};
$SIG{STOP} = sub {$sig{STOP} = 1};
$SIG{INT}  = sub {$sig{INT} = 1};
#$SIG{SUSP} = sub {$sig{SUSP} = 1};

#sub processSignals{
#	my $config = shift;
#	if ( $config->getSig('HUP')) {
# 		$config->resetSig('HUP');
# 		print("testMPU, HUP received");
# 	}	
# 	if ( $config->getSig('USR1')) {
# 		$config->resetSig('USR1');
# 		print("testMPU, USR1 received");
# 	}
# 	if ( $config->getSig('USR2')) {
# 		$config->resetSig('USR2');
# 		print("testMPU, USR2 received");
# 	}
# 	if ( $config->getSig(INT)) {
# 		$config->resetSig(INT);
# 		print("testMPU, INT received");
# 	}
#}	#	processSignals


my $deviceAddress = 0x68;
my $device = MPU6050->new($deviceAddress);
#my $config = RPiConfig->new();
my ($xCal,$yCal,$zCal) = (1.0,1.0,1.0);
#$xCal = $config->{xCal} if defined($config->{xCal});
#$yCal = $config->{yCal} if defined($config->{yCal});
#$zCal = $config->{zCal} if defined($config->{zCal});
#$config->{maxG} = 4 unless (defined($config->{maxG}));
#$config->{I2C_sleep} = 1 unless defined($config->{I2C_sleep});
$device->wakeMPU(4);
print "Waking MPU at maxG = 4\n";
sleep(2);
my $loopDelay = 0.01 * 1000 * 1000;
while( ($sig{INT}==0) && ($sig{QUIT} == 0) &&
       ($sig{STOP} == 0) ) {
#	processSignals($cnfig);
	my ($epoch,$msec) = Time::HiRes::gettimeofday();
	my ($AcX,$AcY,$AcZ) = $device->readAccelG();
	my ($tmp,$tmpC,$tmpF) = $device->readTemp();
    $AcX *= $xCal;
    $AcY *= $yCal;
    $AcZ *= $zCal;
    my $totG = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
	my $line= sprintf("%d,%6d,%04.3f,%04.3f,%04.3f,%04.3f,%d,%04.2f,%04.2f",$epoch,$msec,$totG,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF);
#	my $line= join(',',($epoch,$msec,$totG,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF));
	print "$line\n";
	Time::HiRes::usleep($loopDelay);
}

print "\nExit on Interrupt\n" if ($sig{INT} != 0);
print "\nExit on Stop\n" if ($sig{STOP} != 0);
print "\nExit on Quit\n" if ($sig{QUIT} != 0);

1;
