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

my ($cmd,$addy,$field,$data) = @ARGV;
$addy = hex $addy if (defined($addy));
$field = hex $field if (defined($field));
$data = hex $data if (defined($data));
my $device;
if (defined($cmd) && ($cmd eq 'read')) {
	if ($device = attach($addy)) {
		my ($byte1,$cnt) = getI2CdataByte($device,$field);
		my $str = sprintf("%x" ,$byte1 & 0xFF );
		print "$str\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} elsif (defined($cmd) && ($cmd eq 'write') ) {
	if ($device = attach($addy)) {
		warn "No write function yet\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} else {
	warn "Usage I2Cio.pl [read|write] addy data";
}


1;
