#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";

use RPi::I2C;


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
      }         
   } while ( $chkbyte != 0);
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
         $chksum = ~$databyte;
      }         
   } while ( $databyte != $chksum );
   return( $databyte );
}  # end getByte

my $version = getByte(0x08,0x00);
while (1) {
   # end of 
   my $doors = getByte(0x08,0x03);
   my $door1 = $doors & 0x01;
   my $door2 = ($doors & 0x02) >> 1;
   my $voltage = getByte(0x08,0x0A);
   $voltage = $voltage / 10.0;
   my $tempCnt = getByte(0x08,0x12);
   my ($temp1, $temp2) = (-255.0,-255.0);
   if ($tempCnt > 0) {
      $temp1 = get10Bit(0x08,0x13);
      }
   if ($tempCnt > 1) {
      $temp1 = get10Bit(0x08,0x14);
      }
   my $str = sprintf("%d %d %d %d %d %d %d\n", $version,$voltage,$door1,$door2,$temp1,$temp2);
   print $str;
}

1;
