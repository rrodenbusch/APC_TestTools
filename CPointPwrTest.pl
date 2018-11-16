#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);
use RPi::SPI;
use Net::Ping;

my $maxTestV = 13.8;
my $minTestV = 5;

my $Vref = 5.11;
my $divider0 = .3044; # when discharging
my $divider1 = .2955; # when charging
my $VfPos = .556;  # Diode forward voltage
my $VfGnd = .525;  # Diode forward voltage
my $loopDelay = 3;
my $r1 = 3.88;
my $r2 = 9.25;

my $divider = $r1/ ($r1+$r2);
my $spi = RPi::SPI->new(0);
my $buf = [1,2,3,4,5,6,7,8,9,10];
my $len = 10;

sub checkCPstatus {
   my $status = 0;
   my $p = Net::Ping->new('icmp');
   $status = 1 if ( $p->ping('8.8.8.8') );
   #print "CP Status : $status\n";
   return( $status);
}


sub getCPvoltage {

   my @retdata = $spi->rw($buf,$len);
   my $byte_cnt = scalar(@retdata);

   my $byte_one = $retdata [0];
   my $byte_two = $retdata [1];
   my $highBits = $byte_one & 0x1F; # MSB 5 bits
   my $lowBits = $byte_two & 0xFE;  # LSB 7 bits 
   my $lowByte = ($lowBits >> 1) &   0x007F;
   my $highByte = ($highBits << 7) & 0x0F80;
   my $bitCnt = $highByte | $lowByte;
   my $vRaw = $Vref * ($bitCnt/4096);
   my $charging = `gpio -g read 27`;
   my $divider = $divider0;
   $divider = $divider1 if ($charging == 1);
   my $vScaled = ($vRaw / $divider);
   my $vActual = $vScaled + $VfPos + $VfGnd;
   #my $line = sprintf("%0.3f %0.3f %0.3f %d %0X",
   #                $vActual,$vScaled,$vRaw,$bitCnt,$bitCnt);
   #print "$line\n";
   return($vActual,$vScaled,$vRaw,$bitCnt);
}

my ($powerOnTime,$powerOffTime,$curStatus,$lastGoodStatus,$lastBadStatus) =
                          (0,0,0,0,0);
$curStatus = -1;

## Turn Power On
my $lastStatus = 0;
my ($lastGoodTime,$lastBadTime) = (0,0);
my $powerOn = `gpio -g read 27`;
$powerOn =~ s/\R//g;
my $epoch = time();
my $fname = "CP_PowerTest.$epoch.log";
open (my $fh, ">$fname") or die "Unable to open $fname\n$!\n";
my $timeStr = strftime( "%Y%m%d %H:%M:%S",localtime($epoch));
my ($vActual,$vScaled,$vRaw,$bitCnt) = getCPvoltage();
my $lastV = $vActual;
my $vLine = sprintf("%0.3f,%0.3f,%0.3f,%d,%0X",
                   $vActual,$vScaled,$vRaw,$bitCnt,$bitCnt);
my $powerCycles = 0;
print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Startup Status,$powerOn,$vLine\n";
if ($powerOn == 0) {
   `gpio -g mode 27 out`;
   `gpio -g write 27 1`;
   $powerOn = `gpio -g read 27`;
   $powerOn =~ s/\R//g;
   if ( $powerOn ) {
     $powerOnTime = $epoch;
     print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Power ON OK,$powerOffTime\n";
   }
}

while (1) {
   $epoch = time();
   $timeStr = strftime( "%Y%m%d %H:%M:%S",localtime($epoch));
   ($vActual,$vScaled,$vRaw,$bitCnt) = getCPvoltage();
   if (abs($vActual - $lastV ) > 2) {
      sleep 3;
      ($vActual,$vScaled,$vRaw,$bitCnt) = getCPvoltage();
   }
   if (abs($vActual - $lastV ) > 2) {
      sleep 3;
      ($vActual,$vScaled,$vRaw,$bitCnt) = getCPvoltage();
   }
   $lastV = $vActual;
   $powerOn = `gpio -g read 27`;
   $powerOn =~ s/\R//g;
   $vLine = sprintf("%0.3f,%0.3f,%0.3f,%d,%0X",
                   $vActual,$vScaled,$vRaw,$bitCnt,$bitCnt);
   print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Status,$powerOn,$vLine\n";
   if ( $powerOn ) { # Power is ON
      if ( ( $vActual > $maxTestV ) && ( $lastStatus ) )  {  # Power up on-line
         # turn off power and monitor
         print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Powering Off, $vActual, $maxTestV\n";
         `gpio -g mode 27 out`;
         `gpio -g write 27 0`;
         $powerOn = `gpio -g read 27`;
         $powerOn =~ s/\R//g;
         if ($powerOn == 0) {
            print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Power OFF OK,$powerOnTime\n";
            $powerOffTime = $epoch;
         }
      }
   } else { # Power is Off
      if ($vActual < $minTestV) {
         # turn on power
         print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Powering On, $vActual < $minTestV\n";
         `gpio -g mode 27 out`;
         `gpio -g write 27 1`;
         $powerOn = `gpio -g read 27`;
         $powerOn =~ s/\R//g;
         if ($powerOn) { 
             print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,Power ON OK,$powerOffTime\n";
             $powerOnTime = $epoch;
             $powerCycles++;
         }
      }
   }

   #
   ## check the cradlepoint
   #
   $curStatus = checkCPstatus();
   $lastGoodTime = $epoch if ($curStatus);
   $lastBadTime = $epoch unless($curStatus);
   if ($curStatus != $lastStatus) {  # status change
      if ($curStatus) {
         print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,CPoint Online\n";
      } else {
         print $fh "$epoch,$timeStr,$powerCycles,$lastStatus,CPoint Offline\n";
      }
   }
   $lastStatus = $curStatus;

   sleep($loopDelay);
}

1;
