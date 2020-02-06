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
use POSIX;

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
sleep(1);
my $loopDelay = $delaySec * 1000 * 1000;
my ($errCnt,$curErr,$tmpErr,$accErr,$samples) = (0,0,0,0,0);
my ($StartEpoch,$StartMsec) = Time::HiRes::gettimeofday();
my ($totX,$totY,$totZ) = (0,0,0);
my $goodCnt=0;
while( ($sig{INT}==0) && ($sig{QUIT} == 0) &&
       ($sig{STOP} == 0) && ($samples < 1000) ) {
   $curErr = 0;
   $samples++;
   my ($epoch,$msec) = Time::HiRes::gettimeofday();
   my ($AcX,$AcY,$AcZ) = $device->readAccelRaw();
   my $AX = ($AcX & 0x8000) ? -((~$AcX & 0xffff) + 1) : $AcX;
   my $AY = ($AcY & 0x8000) ? -((~$AcY & 0xffff) + 1) : $AcY;
   my $AZ = ($AcZ & 0x8000) ? -((~$AcZ & 0xffff) + 1) : $AcZ;

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
   if ( ($AcX != -1) && ($AcY != -1) && ($AcZ != -1) ) {
      $goodCnt++;
      $totX += $AX;
      $totY += $AY;
      $totZ += $AZ;
   }
 #  $AcX *= $xCal;
 #  $AcY *= $yCal;
 #  $AcZ *= $zCal;
   my $totG = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
   my $line= sprintf("%d,%06d,%04.3f,%04.3f,%04.3f,%04.3f,%d,%04.2f,%04.2f,%d",
                     $epoch,$msec,$totG,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF,$curErr);
   print "$line\n";
   Time::HiRes::usleep($loopDelay);
}
my ($xMPU,$yMPU,$zMPU) = (0,0,0);
if ($goodCnt > 0) {
   $xMPU = floor(0 - $totX / $goodCnt);
   $yMPU = floor(0 - $totY / $goodCnt);
   $zMPU = floor(8192 - $totZ / $goodCnt);
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
$line = sprintf("Offsets %6.2f %6.2f %6.2f\n", $xMPU, $yMPU, $zMPU);
print $line;
print "Update config file? [Y|n]? ";
my $ans = <STDIN>;
$ans =~ s/\R//g;
print "\nupdating config file\n" if (($ans eq 'Y') || ($ans eq 'y'));
1;
