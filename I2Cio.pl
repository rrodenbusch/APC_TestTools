#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";
use Time::HiRes qw(time sleep usleep);

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
	my $retries = 50;
	my $word1 = $device->read_word($cmd);
	while (($word1 == -1) && ($retries > 0) ) {
		usleep(50);
		$retries--;
		$word1 = $device->read_word($cmd);
	}
	$word1 = (($word1 & 0xFF00)>>8) |(($word1 & 0x00FF) << 8) unless ($word1 == -1);
	return($word1,(50-$retries));
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
my @Bits = (0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80);

my ($cmd,$addy,$register,$data) = @ARGV;
$addy = hex $addy if (defined($addy));
$register = hex $register if (defined($register));
#$data = hex $data if (defined($data));
my $device;
if (defined($cmd) && ($cmd eq 'read')) {
	if ($device = attach($addy)) {
		sleep(1);
		my $byte1;
		while ( ($byte1 = $device->read_byte($register)) == -1) {
			print "Read Error\n";
			sleep(1);
		}
		my $str = sprintf("%02X %02X %02X %08b" ,$addy,$register,$byte1,$byte1);
		print "0x$str\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} elsif (defined($cmd) && ($cmd eq 'readword')) {
	if ($device = attach($addy)) {
		sleep(1);
		my $word1;
		while ( ($word1 = $device->read_word($register) == -1) {
			"Read Error\n";
			sleep(1);	
		}
		my $str = sprintf("%04X %06d %16b" ,$word1 & 0xFFFF,
				$word1 & 0xFFFF, $word1 & 0xFFFF );
		print "Word $word1 :: $str\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}
} elsif (defined($cmd) && ($cmd eq 'readwordchk')) {
	if ($device = attach($addy)) {
		my $cnt = 0;
		my ($word1,$retries1) = getI2CdataWord($device,$register);
		my ($word2,$retries2) = getI2CdataWord($device,$register+1);
		my $totTries = $retries1 + $retries2;
		while (~$word1 != $word2) {
			$cnt++;
			my $str2 = sprintf("Chksum Error $cnt %04X %04X\n",$word1,$word2);
			usleep(50);
			($word1,$retries1) = getI2CdataWord($device,$register);
			($word2,$retries2) = getI2CdataWord($device,$register+1);
			$totTries += $retries1 + $retries2;
		}
		my $str = sprintf("%04X %06d %16b @%02d" ,$word1 & 0xFFFF,
				$word1 & 0xFFFF, $word1 & 0xFFFF, $totTries );
		print "Word $word1 :: $str\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
}	elsif (defined($cmd) && ($cmd eq 'readblock')) {
	if ($device = attach($addy)) {
		my @buf = readI2Cblock($device,$register,1000,$data);
      my $curVal = bytesToint($buf[0],$buf[1]) / 10;
      my $maxVal = bytesToint($buf[2],$buf[3]) / 10;
      my $minVal = bytesToint($buf[4],$buf[5]) / 10;
      print "$curVal  $maxVal $minVal\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
}  elsif (defined($cmd) && ($cmd eq 'write') ) {
	if ($device = attach($addy)) {
		sleep(1);
		my ($byte1,$byte2);
		while ( ($byte1 = $device->read_byte($register)) == -1) {
			print "Read Error\n ";
			sleep(1);
		};
		while ($device->write_byte($data, $register) == -1) {
    		print "Write Error\n";    	
            sleep(1);
        }
		while ( ($byte2 = $device->read_byte($register)) == -1) {
			print "Read Error2\n ";
			sleep(1);
		}
        my $str = sprintf("Register %02X was %02X is %02x\n",$register,$byte1,$byte2);
        print "$str";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} elsif (defined($cmd) && ($cmd eq 'writeword') ) {
	if ($device = attach($addy)) {
		sleep(1);
		my $byte1 = $device->read_word($register);
		$device->write_word($data & 0xFFFF, $register);
                sleep(1);
		my $byte2 = $device->read_word($register);
                my $str = sprintf("Register %04X was %04X is %04X\n",$register,$byte1,$byte2);
                print "$str";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} else {
	warn "Usage I2Cio.pl [read|write] addy data";
}


1;
