#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";

use RPi::I2C;
use MPU6050;

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
#
sub queryI2Cbus {
   my $ValidI2C = shift;
   
   my $return = `i2cdetect -y 1`;
   print $return;
   my @lines = split("\n",$return);
   shift(@lines); # header
   my $addy = 0x00;
   foreach my $line (@lines) {
      my $lineNum = substr($line,0,2);
      my $offset = 4;
      my $inc = 3;         
      for (my $i = 0; $i<16; $i++) {
         if ($addy <= 0x7F) {
            my $curAddy = substr($line,$offset,2);
            if ( ($curAddy ne "  ") && ($curAddy ne "--")) {
               my $numAddy = hex("0x".$curAddy);
               ${$ValidI2C}[$addy] = ($numAddy == $addy);
            }
            $offset += $inc;
            $addy++;
         }
      }
   }

   for (my $i =0; $i<=0x7F; $i++) {
      if (${$ValidI2C}[$i]) {
         my $str = sprintf("Found %02X\n",$i);
         print $str;
      }
   }
}

my @ValidI2C;
queryI2Cbus(\@ValidI2C);
#if ($ValidI2C[0x0e]) {
#   my $device = attach(0x0E);
#   my $uid = readI2Cblock($device,0xFF,4);
 #  my $str = "UID 0x0E [Arduino]: %02X %02X %02X %02X\n",$uid[0], $uid[1], $uid[2], $uid[3]);
 #  print $str;
#}

if ($ValidI2C[0x68] ) { # check the MPU6050
   print "Checking MPU\n"; 
   my $device = MPU6050->new(0x68);
   $device->wakeMPU(4);
   sleep(2);
	my ($AcX,$AcY,$AcZ) = $device->readAccelG();
	my ($tmp,$tmpC,$tmpF) = $device->readTemp();
	my $line= sprintf( "MPU Data:: Ax: %4.2f Ay: %4.2f Az: %4.2f TempF %4.2tmpF\n", $AcX,$AcY,$AcZ,$tmpF);
	print "$line\n";
}
1;
