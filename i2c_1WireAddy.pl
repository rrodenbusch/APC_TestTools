#!/usr/bin/perl
#################################################
#
#
#	i2c_1WireAddy.pl
#
#
#   Get the addresses of the devices on the 1 Wire bus
#
#################################################
use lib "$ENV{HOME}/APC_TestTools";
use warnings;
use strict;
use RPi::I2C;

sub attach {
	my $addy = shift;
	my ($device,$retval);

	if ($device = RPi::I2C->new($addy)) {
		$retval = $device if ( $device->check_device($addy) );		
	}
	return ($retval);
}

if (my $device = attach(0x57)) {
	# get FBD UID
    my $byte1 = $device->read_byte(0xFC);
    my $byte2 = $device->read_byte(0xFD);
    my $byte3 = $device->read_byte(0xFE);
    my $byte4 = $device->read_byte(0xFF);
	my $line= sprintf( "FBD UID: %02X %02X %02X %02X\n",$byte1,$byte2,$byte3,$byte4);
	print $line;

} else {
	print "Unable to read FBD UID\n";
}
         
         
if (my $device = attach(0x0f)) {
    	my $byte1 = $device->read_byte(0x00);
	my $line= sprintf( "FBD ARD Version: %02X\n",$byte1);
 	print $line;
	my $numDevs = $device->read_byte(0x04);
	$line = sprintf( "Found %02d devices on 1 Wire Bus\n",$numDevs);
	print $line;
	my $devNum = 0;
	while ($numDevs > 0) {
		$device->write_byte($devNum,0xA0);	# select the device address
		sleep(2);
		my @Address;
		for (my $i = 0; $i < 8; $i++ ) {
                   my $reg = 0xA1 + $i;
		   $Address[$i] = $device->read_byte($reg);
		}
		$line = sprintf( "Device %02d : %02X %02X %02X %02X %02X %02X %02X %02X\n",
			$devNum,@Address);
		print $line;
		$devNum++;
		$numDevs--;
	}
} else {
	print "Error attaching to device 0x0F\n";
}


1;
