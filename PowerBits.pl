#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";
my $addy = 0x21;
use RPi::I2C;

sub readI2Cbyte {
	my ($device,$timeout) = @_;
	my ($data,$retData) = (-1,-1);
	my $cnt = 0;
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;

	do {  # wait for return a max of one second
		$data = $device->read(0x09);
		Time::HiRes::usleep($delaytics) if (!defined($data) || ($data == -1)); # milliseconds
	} while ( (!defined($data)  || ($data == -1)) && ($cnt++ < $loopcnt) );
	$retData = $data if ($data != -1);  # return undefined in no return values available
	
	return ($retData,$cnt);
}

my $powerbits = 0;
print "Power Bits\n";
my $dev = RPi::I2C->new($addy);
my $str = "        ";
while (1) {
      if ($dev->check_device($addy)) {
      $powerbits = $dev->read_byte(0x09);
      $str = sprintf("%08b\r", $powerbits & 0xFF);
   } else {
      $str = "        \r";
   }
   print $str;
   
}

1;
   
   
   
