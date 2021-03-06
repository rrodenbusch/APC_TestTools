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

my $delaySec = 0.01;
$delaySec = $ARGV[0] if defined($ARGV[0]);
print "Configuring MPU; delay $delaySec\n";
my $deviceAddress = 0x68;
my $device = MPU6050->new($deviceAddress);
my ($xCal,$yCal,$zCal) = (1.0,1.0,1.0);
$device->wakeMPU(4);
print "Waking MPU at maxG = 4\n";
sleep(0.5);
print "Begining sample...\n";

my $loopDelay = $delaySec * 1000 * 1000;
my ($errCnt,$curErr,$tmpErr,$accErr,$samples) = (0,0,0,0,0);
my ($StartEpoch,$StartMsec) = Time::HiRes::gettimeofday();
my $loopcnt = 1000;
while( ($sig{INT}==0) && ($sig{QUIT} == 0) &&
       ($sig{STOP} == 0) && ($loopcnt > 0) ) {
   $curErr = 0;
   $loopcnt--;
   $samples++;
   my ($epoch,$msec) = Time::HiRes::gettimeofday();
   my ($AcX,$AcY,$AcZ) = $device->readAccelG();
   my ($GyX,$GyY,$GyZ) = $device->readGyroDegSec();
   my ($tmp,$tmpC,$tmpF) = (0,0,0);
   ($tmp,$tmpC,$tmpF) = $device->readTemp() if ($delaySec != 0);
   if ( ($AcX == -1) || ($AcY == -1) || ($AcZ == -1) || ($tmp == -1) ) {
      $curErr = -1;
      $tmpErr++ if ($tmp == -1);
      $accErr++ if ($tmp != -1);
      $errCnt++ if ($AcX == -1);
      $errCnt++ if ($AcY == -1);
      $errCnt++ if ($AcZ == -1);
      $errCnt++ if ($tmp == -1);
   }
   $AcX *= $xCal;
   $AcY *= $yCal;
   $AcZ *= $zCal;
   my $totG = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
   my $line= sprintf("%d,%06d, ACCEL(g) tot... %04.3f,%04.3f,%04.3f,%04.3f, GYRO (deg/s) %04.3f,%04.3f,%04.3f, TEMP %d,%04.2f,%04.2f, ERRS %d",
                     $epoch,$msec,$totG,$AcX,$AcY,$AcZ,$GyX,$GyY,$GyZ,$tmp,$tmpC,$tmpF,$curErr);
   print "$line\n";
   Time::HiRes::usleep($loopDelay);
}
my ($EndEpoch,$EndMsec) = Time::HiRes::gettimeofday();
my $SampleTime = ($EndEpoch - $StartEpoch) + ($EndMsec - $StartMsec) / 1000000;
my $SampleRate = $samples/$SampleTime;
print "\nExit on Interrupt\n" if ($sig{INT} != 0);
print "\nExit on Stop\n" if ($sig{STOP} != 0);
print "\nExit on Quit\n" if ($sig{QUIT} != 0);
my $line = sprintf("Count %d Rate %6.2f Time %6.2f\n",$samples,$SampleRate,$SampleTime); 
print "Errs(Tot TmpErr AccErr) $errCnt $tmpErr $accErr\n";
print $line;

1;
