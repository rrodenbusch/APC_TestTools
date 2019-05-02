#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";

use RPi::I2C;

sub readI2Cbyte {
	my ($device,$timeout) = @_;
	my ($data,$retData) = (-1,-1);
	my $cnt = 0;
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;

	do {  # wait for return a max of one second
		$data = $device->read();
		Time::HiRes::usleep($delaytics) if (!defined($data) || ($data == -1)); # milliseconds
	} while ( (!defined($data)  || ($data == -1)) && ($cnt++ < $loopcnt) );
	$retData = $data if ($data != -1);  # return undefined in no return values available
	
	return ($retData,$cnt);
}
sub readI2Cword {
	my ($device,$cmd,$timeout) = @_;
	my ($data,$retData,@bytes);
	my $cnt = 0;
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;

	do {  # wait for return a max of one second
		@bytes = $device->read_block(2,$cmd);
		Time::HiRes::usleep($delaytics) if (!defined($bytes[0])); # milliseconds
	} while ( (!defined($bytes[0])) && ($cnt++ < $loopcnt) );
	return (@bytes);
}

sub readI2Cblock {
	my ($device,$cmd,$timeout,$cnt) = @_;
	my ($data,$retData,@bytes);
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;

	do {  # wait for return a max of one second
		@bytes = $device->read_block($cnt,$cmd);
		Time::HiRes::usleep($delaytics) if (!defined($bytes[0])); # milliseconds
	} while ( (!defined($bytes[0])) && ($cnt++ < $loopcnt) );
	return (@bytes);
}
sub getI2CdataByte {
	my ($device,$cmd,$timeout) = @_;
	$timeout = 1000 if !defined($timeout);  # default time is 1 second
	$device->write($cmd);
	my ($byte1,$cnt) = readI2Cbyte($device,$timeout);
	return($byte1,$cnt);
}
sub getI2CdataWord {
	my ($device,$cmd,$timeout) = @_;
	my @bytes;
	$timeout = 1000 if !defined($timeout);  # default time is 1 second
	@bytes = readI2Cword($device,$cmd,$timeout);
	my $retVal = (($bytes[0] & 0xFF) << 8) | ($bytes[1] & 0xFF);
	return($retVal);
}

sub attach {
	my $addy = shift;
	my ($device,$retval);

	if ($device = RPi::I2C->new($addy)) {
		$retval = $device if ( $device->check_device($addy) );		
	}
	return ($retval);
}
sub bytesToint {
   my @bytes = @_;
   my $retVal;
   if ($bytes[0] & 0x80) {
      $retVal = (($bytes[0] & 0xFF) << 8) | ($bytes[1] & 0xFF);
      $retVal = ~$retVal;
      $retVal = ($retVal + 1) & 0xFFFF; 
      $retVal = -1 * $retVal;
   } else {  # Positive Int
      $retVal = (($bytes[0] & 0xFF) << 8) | ($bytes[1] & 0xFF);
   }
   return($retVal);
}

sub GPIO_setPinValue {
	my ($addy,$pin,$value) = @_;
	if (my $device = attach($addy)) {
		my $curCfg = $device->read_byte(0x00);
		my $curVal = $device->read_byte(0x0A);
		my $pinBit = $Bits[$pin];
		if (defined($pinBit)) {
			$curCfg = $curCfg | $pinBit;
			if ($value == 0) {
				$curVal ~= $pinBit;
			} else {
				$curVal |= $pinBit;
			}
			$device->write_byte(0x0A,$curVal);
			$device->write_byte(0x00,$curCfg);
		} else {
			print(STDERR,"Unable to get pin id for pin %02d\n",$pin);
		}
	} else {
		print(STDERR,"Unable to attach to device %02X\n",$addy);
	}
}
sub GPIO_setPinMode {
	my ($addy,$pin,$value) = @_;
	if (my $device = attach($addy)) {
		my $curCfg = $device->read_byte(0x00);
		my $curVal = $device->read_byte(0x0A);
		my $pinBit = $Bits[$pin]; 
		if (defined($pinBit)) {
			$curCfg = $curCfg | $pinBit;
			if ($value == 0) {
				$curVal ~= $pinBit;
			} else {
				$curVal |= $pinBit;
			}
			$device->write_byte(0x0A,$curVal);
			$device->write_byte(0x00,$curCfg);
		} else {
			print(STDERR,"Unable to get pin id for pin %02d\n",$pin);
		}
	} else {
		print(STDERR,"Unable to attach to device %02X\n",$addy);
	}
}

my($addy,$pin,$value) = (0x22,0x00,0x01);
($addy,$pin,$value) = @_ if (defined($_[0]));

GPIO_setPinValue($addy,$pin,$value);
sleep(30);
GPIO_setPinValue($addy,$pin,~$value);
GPIO_setPinMode($add,0);

1;
