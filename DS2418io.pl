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

sub writeDS2482 {
   my ($addy,$register,$data,$retreg) = @_;
   my ($device, $byte2);
   
   if ($device = attach($addy)) {
	   my $byte1 = $device->read_byte($register);
		$device->write_byte($data & 0xFF, $register);
      sleep(1);
		$byte2 = $device->read_byte($register);
      my $str = sprintf("Register %02X was %02X is %x\n",$register,$byte1,$byte2);
      print "$str";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}
   return ($byte2);
}

my ($cmd,$addy,$register,$data) = @ARGV;
$addy = hex $addy if (defined($addy));
$register = hex $register if (defined($register));
$data = hex $data if (defined($data));
my $device;
if (defined($cmd) && ($cmd eq 'read')) {
	if ($device = attach($addy)) {
#		my ($byte1,$cnt) = getI2CdataByte($device,$register);
		my $byte1 = $device->read_byte($register);
		my $str = sprintf("%02X %03d %08b" ,$byte1 & 0xFF,
				$byte1 & 0xFF, $byte1 & 0xFF );
                $data--;
                while ($data > 0) {
                   $register++;
		   $byte1 = $device->read_byte($register);
		   $str = sprintf("%02X %03d %08b" ,$byte1 & 0xFF,
				$byte1 & 0xFF, $byte1 & 0xFF );
                   $data --;
                }
		print "0x$str\n";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} elsif (defined($cmd) && ($cmd eq 'write') ) {
	if ($device = attach($addy)) {
		my $byte1 = $device->read_byte($register);
		$device->write_byte($data & 0xFF, $register);
                sleep(1);
		my $byte2 = $device->read_byte($register);
                my $str = sprintf("Register %02X was %02X is %x\n",$register,$byte1,$byte2);
                print "$str";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}	
} elsif (defined($cmd) && ($cmd eq 'reset')) {
  if ($device = attach($addy)) {
	   # my $byte1 = $device->read_byte($register);
		$device->write_byte(0x00,0xF0);
      my $status = $device->read();
      if ( ($status & 0xF7) == 0x10 ) {
         print "Device Reset OK\n";
      } else {
         print "Device Reset Error\n";
      }  
   }
} elsif (defined($cmd) && ($cmd eq 'config')) {
  if ($device = attach($addy)) {
	   # my $byte1 = $device->read_byte($register);
		$device->write_byte(0xE1, 0xD2);
      my $config = $device->read();
      if ( $config == 0x01 ) {
         print "Device config OK\n";
      } else {
         print "Device config Error\n";
      }
   }   
} elsif (defined($cmd) && ($cmd eq 'getconfig')) {
  if ($device = attach($addy)) {
		$device->write_byte(0xC3, 0xE1);
      my $config = $device->read();
      my $str = sprintf("Config is %02X %03d %08b\n",$config,$config,$config);
      print $str;
   }   
} elsif (defined($cmd) && ($cmd eq 'getstatus')) {
  if ($device = attach($addy)) {
		$device->write_byte(0xF0, 0xE1);
      my $status = $device->read();
      my $str = sprintf("Status is %02X %03d %08b\n",$status,$status,$status);
      print $str;
   }   
} elsif (defined($cmd) && ($cmd eq '1reset')) {
  if ($device = attach($addy)) {
		$device->write_byte(0, 0xB4);
      #sleep(1);
		my $status = 0;
      my $cnt = 0;
      do {
         $status = $device->read();
         if ($status & 0x01) {
            my $l = sprintf("Status cnt %d is: %02x\n",$cnt,$status);
            $cnt++;
            #sleep(0.01);
         }
      } while (($status & 0x01) && ($cnt < 20));
      my $str = sprintf("Cnt %d, Status is %02X %03d %08b\n",$cnt,$status,$status,$status);
      print "$str";
	} else {
		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
	}
} else {
	warn "Usage I2Cio.pl [read|write|reset|config|1reset] addy data";
}


1;
