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
      $doorStat[0] = ($doorLeft == 0) ? "CLOSED " : "OPEN   ";
      $doorStat[1] = ($doorRight == 0) ? "CLOSED " : "OPEN   ";
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

sub getUpperGPIO { # Pins 2 through 9
   my ($addy) = @_;
   my $cmd = 0x11;
   my $GPIO = getByte($addy,$cmd);
   return ($GPIO);
}
sub setGPIOstr {
   my ($lower,$upper) = @_;
   my $str = '';
   if ($lower & 0x01) {
      $str .= " 1Wire  HIGH";
      } else {
      $str .= " 1Wire  LOW ";
      }
   if ($lower & 0x02) {
      $str .= " NUC    HIGH";
      } else {
      $str .= " NUC    LOW ";
      }
   if ($lower & 0x04) {
      $str .= " Bridge HIGH";
      } else {
      $str .= " Bridge LOW ";
      }
      
   if ($lower & 0x08) {
      $str .= " ORIDE  HIGH";
      } else {
      $str .= " ORIDE  LOW ";
      }
   if ($lower & 0x10) {
      $str .= " RPi    HIGH";
      } else {
      $str .= " RPi    LOW ";
      }
   if ($lower & 0x20) {
      $str .= " NVN    HIGH";
      } else {
      $str .= " NVN    LOW ";
      }
   if ($lower & 0x40) {
      $str .= " Door1  HIGH";
      } else {
      $str .= " Door1  LOW ";
      }
   if ($lower & 0x80) {
      $str .= " Door2   HIGH";
      } else {
      $str .= " Door2   LOW ";
      }
   if ($upper & 0x01) {
      $str .= " Batt2   HIGH";
      } else {
      $str .= " Batt2   LOW ";
      }
   if ($upper & 0x02) {
      $str .= " Pwr2    HIGH";
      } else {
      $str .= " Pwr2    LOW ";
      }
   if ($upper & 0x04) {
      $str .= " Batt1   HIGH";
      } else {
      $str .= " Batt1   LOW ";
      }
   if ($upper & 0x08) {
      $str .= " Pwr1    HIGH";
      } else {
      $str .= " Pwr1    LOW ";
      }

   return($str);
}

sub getSoundVals {
   my ($addy) = @_;
   my $max0 = get10Bit($addy,0x30);
   my $avg0 = get10Bit($addy,0x31);
   my $sig0 = get10Bit($addy,0x32);
   my $max1 = get10Bit($addy,0x33);
   my $avg1 = get10Bit($addy,0x34);
   my $sig1 = get10Bit($addy,0x35);
   my $events0 = getByte($addy,0x36);
   my $events1 = getByte($addy,0x37);
   return($max0,$avg0,$sig0,$events0,$max1,$avg1,$sig1,$events1);
}

my $version = getByte(0x08,0x00);
while (1) {
   # end of 
   my ($doorLeft,$doorRight) = getDoors(0x08);
   my $voltage = getVoltage(0x08);
   my $lower = getLowerGPIO(0x08);
   my $upper = getUpperGPIO(0x08);
   
   my $tempCnt = getByte(0x08,0x12);
   my ($temp1, $temp2) = (-255.0,-255.0);
   if ($tempCnt > 0) {
      $temp1 = get10Bit(0x08,0x13);
      $temp1 = $temp1 /10.0;
      }
   if ($tempCnt > 1) {
      $temp2 = get10Bit(0x08,0x14);
      $temp2 = $temp2 / 10.0;
      }
   my $gpStr = setGPIOstr($lower,$upper);
   my @Sounds = getSoundVals(0x08);
   my $sndStr = join(",",@Sounds);
   my $str = sprintf("Version:%d %04.2fV Left:%06s Right:%06s Blower:%4.1f Intake:%4.1f Lower:%08b Upper:%04b\n", 
               $version,$voltage,$doorLeft,$doorRight,$temp1,$temp2, $lower, $upper & 0x0F);
#   print "$sndStr\n";
   print $str;
#   print "$gpStr\n";
   sleep (1);
}

1;
