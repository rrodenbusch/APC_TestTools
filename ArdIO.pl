#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";

use RPi::I2C;
my    $MAXTRIES = 50;


sub attach {
	my $addy = shift;
	my ($device,$retval);

	if ($device = RPi::I2C->new($addy)) {
		$retval = $device if ( $device->check_device($addy) );		
	}
	return ($retval);
}


sub get10Bit {
   my ($addy,$cmd) = @_;
   my ($device,$word1,$databyte,$chkbyte,$chksum);
   my $cnt = 0;
   do {
      if ($device = attach($addy) ) {   
         $word1 = $device->read_word($cmd);
         my $n1 = $word1 & 0x00F;
         my $n2 = ($word1 & 0x0F0) >> 4;
         my $n3 = ($word1 & 0xF00) >> 8;
         my $n4 = ($word1 & 0xFF00) >> 12;
         $chkbyte = 0;
         $chkbyte ^= $n1;
         $chkbyte ^= $n2;
         $chkbyte ^= $n3;
         $chkbyte ^= $n4;
      } else {
         $cnt++;
         $chkbyte = 0xFF;
         $word1 = 0xFFFF;
      }         
   } while ( ($cnt < $MAXTRIES) && ($chkbyte != 0) );
   return( $word1 & 0x3FF);
}

sub getByte {
   my ($addy,$cmd) = @_;
   my ($device,$word1,$databyte,$chkbyte,$chksum);
   my $cnt = 0;
   do {
      if ($device = attach($addy) ) {   
         $word1 = $device->read_word($cmd);
         $databyte = $word1 & 0xFF;
         $chkbyte = ($word1 >> 8) & 0xFF;
         $chksum = (~$chkbyte) & 0xFF;
      } else {
         $cnt++;
         $databyte = 0xFF;
         $chksum = ~$databyte;
      }         
   } while ( ($databyte != $chksum ) && ($cnt < $MAXTRIES) );
   return( $databyte );
}  # end getByte

sub getDoors {
   my ($addy) = @_;
   my $cmd = 0x03;
   my $doors = getByte($addy,$cmd);
   my @doorStat = ( "UNKNOWN","UNKNOWN");
   if ($doors <= 0x03) {
      my $doorRight = $doors & 0x01;
      my $doorLeft = ($doors & 0x02) >> 1;
      #  Old FBD has pin high on open door1
      $doorStat[0] = ($doorLeft == 0) ? "CLOSED" : "OPEN   ";
      $doorStat[1] = ($doorRight == 0) ? "CLOSED" : "OPEN   ";
   }
   # Return Left / Right
   return($doorStat[0],$doorStat[1]);
}

sub getVoltage {
   my ($addy) = @_;
   my $cmd = 0x0A;
   my $voltage = getByte($addy,$cmd);
   $voltage = $voltage / 10.0;
   return ($voltage);
}

sub getLowerGPIO { # Pins 2 through 9
   my ($addy) = @_;
   my $cmd = 0x10;
   my $GPIO = getByte($addy,$cmd);
   return ($GPIO);
}

my $version = getByte(0x08,0x00);
while (1) {
   # end of 
   my ($doorLeft,$doorRight) = getDoors(0x08);
   my $voltage = getVoltage(0x08);
   my $GPIO = getLowerGPIO(0x08);
   
   my $tempCnt = getByte(0x08,0x12);
   my ($temp1, $temp2) = (-255.0,-255.0);
   if ($tempCnt > 0) {
      $temp1 = get10Bit(0x08,0x13);
      }
   if ($tempCnt > 1) {
      $temp2 = get10Bit(0x08,0x14);
      }
   my $str = sprintf("Version:%d %04.2fV Left:%d Right:%d Blower:%06.1f Intake%d %d GPIO %08b\n", 
               $version,$voltage,$doorLeft,$doorRight,$temp1,$temp2, $GPIO);
   print $str;
   sleep (1);
}

1;
