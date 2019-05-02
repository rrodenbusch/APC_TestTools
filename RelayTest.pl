#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";

use RPi::I2C;
my @Bits = (0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80);

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
			$curCfg &= ~$pinBit;
			if ($value == 0) {
				$curVal &= ~$pinBit;
			} else {
				$curVal |= $pinBit;
			}
			$device->write_byte($curVal,0x0A);
			$device->write_byte($curCfg,0x00);
		} else {
			my $line = sprintf("Unable to get pin id for pin %02d\n",$pin);
			print STDERR $line;
		}
	} else {
		my $line = sprintf("Unable to attach to device %02X\n",$addy);
		print STDERR $line;
	}
}
sub GPIO_setPinMode {
	my ($addy,$pin,$value) = @_;
	if (my $device = attach($addy)) {
		my $curCfg = $device->read_byte(0x00);
		my $curVal = $device->read_byte(0x0A);
		my $pinBit = $Bits[$pin]; 
		if (defined($pinBit)) {
			if ($value == 1) { # set it to input
				$curVal &= ~$pinBit;
				$curCfg = $curCfg | $pinBit;
			} else {   # set it to output
				$curCfg &= ~$pinBit;
			}
			$device->write_byte(0x0A,$curVal);
			$device->write_byte(0x00,$curCfg);
		} else {
			my $line = sprintf("Unable to get pin id for pin %02d\n",$pin);
			print STDERR $line
		}
	} else {
		my $line = sprintf("Unable to attach to device %02X\n",$addy);
		print STDERR $line;
	}
}

my($addy,$pin,$value) = (0x22,0x00,0x01);
($addy,$pin,$value) = @_ if (defined($_[0]));

sub sensorOff {
	GPIO_setPinValue(0x22,0,1);
}
sub sensorOn {
	GPIO_setPinValue(0x22,0,0);
	GPIO_setPinMode(0x22,0,1)
}
sub camOff {
	GPIO_setPinValue(0x22,1,1);
}
sub camOn {
	GPIO_setPinValue(0x22,1,0);
	GPIO_setPinMode(0x22,1,1)
}

sub BrdgOff {
	GPIO_setPinValue(0x22,2,1);
}
sub BrdgOn {
	GPIO_setPinValue(0x22,2,0);
	GPIO_setPinMode(0x22,2,1)
}

sub PiOff {
	GPIO_setPinValue(0x22,3,1);
}
sub PiOn {
	GPIO_setPinValue(0x22,3,0);
	GPIO_setPinMode(0x22,3,1)
}

sub tNetOff {
	GPIO_setPinValue(0x22,5,1);
}
sub tNetOn {
	GPIO_setPinValue(0x22,5,0);
	GPIO_setPinMode(0x22,5,1)
}
sub NUC1Off {
	GPIO_setPinValue(0x22,7,1);
}
sub NUC1On {
	GPIO_setPinValue(0x22,7,0);
	GPIO_setPinMode(0x22,7,1)
}

sub NVNOff {
	GPIO_setPinValue(0x22,4,0);
}
sub NVNOn {
	GPIO_setPinValue(0x22,4,0);
	GPIO_setPinMode(0x22,4,1)
}

sub NUC2Off {
	GPIO_setPinValue(0x22,6,0);
}
sub NUC2On {
	GPIO_setPinValue(0x22,6,0);
	GPIO_setPinMode(0x22,6,1)
}

while (1) {
	BrdgOff();
	sleep(1);
	sensorOff();
	sleep(1);
	camOff();
	sleep(1);
	NVNOff();
	sleep(1);
	tNetOff();
	sleep(1);
	NUC2Off();
	sleep(1);
	NUC2On();
	sleep(1);
	NUC1Off();
	sleep(1);
	
	BrdgOn();
	sleep(1);
	sensorOn();
	sleep(1);
	camOn();
	sleep(1);
	NVNOn();
	sleep(1);
	tNetOn();
	sleep(1);
	NUC2On();
	sleep(1);
	NUC2Off();
	sleep(1);
	NUC1Off();
	sleep(1);
	
	
}


1;
