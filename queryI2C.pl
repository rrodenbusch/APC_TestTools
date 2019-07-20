#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/APC_TestTools";
#use lib "$ENV{HOME}/RPi";

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
   # print $return;
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
}

my @Ards = (0x0a, 0x0f);
my @UIDs = (0x51,0x52,0x53,0x54,0x55,0x56,0x57);
my @GPIOs = (0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27);
my @MPUs = (0x68,0x069);
my @OneWires = (0x1b);
my $DeviceNames = { 0x0a => "RelayArd", 0x0f => "FBD_Ard", 0x1b => "FBD_1Wire",
            0x20 => "BrkrGPIO", 0x21 =>"RelaySns", 0x22=>"RelayCtrl", 0x23=>"GPIOx23",
            0x24 => "GPIOx24", 0x25 => "GPIOx25", 0x26=> "FBD_Sns", 0x27 => "FBD_DIO", 
            0x48=>  "FBDa2d",
            0x51 => "RelayUID", 0x52=> "BreakerUID",0x53=>"UIDx53", 0x54=>"UIDx54", 
            0x55 => "BridgeUID", 0x56=>"UIDx56", 0x57 => "FBD_UID",
            0x68 => "RelayMPU",0x69=>"MPUx69" };

my @ValidI2C;
my $device;
my $curAddy;
queryI2Cbus(\@ValidI2C);

for (my $i =0; $i<=0x7F; $i++) {
   if ($ValidI2C[$i]) {
      my $str = sprintf("Found %02X :: $DeviceNames->{$i}\n",$i);
      print $str;
   }
}

foreach $curAddy (@Ards) {
   if ($ValidI2C[$curAddy] ) { # check the Arduinos
      print "\nChecking $DeviceNames->{$curAddy}\n";
      if ($device = attach($curAddy)) {
         my $byte1 = $device->read_byte(0x00);
         my $line= sprintf( "Version: %04X\n",$byte1);
         print "$line\n";
      } else {
         print "Error attaching to $curAddy\n";
      }
   }
}

foreach $curAddy (@UIDs) {
   if ($ValidI2C[$curAddy] ) { # check the Arduinos
      print "\nChecking $DeviceNames->{$curAddy}\n";
      if ($device = attach($curAddy)) {
         my ($byte1,$cnt1) = getI2CdataByte($device,0xFC); 
         my ($byte2,$cnt2) = getI2CdataByte($device,0xFD); 
         my ($byte3,$cnt3) = getI2CdataByte($device,0xFE); 
         my ($byte4,$cnt4) = getI2CdataByte($device,0xFF); 
         my $line= sprintf( "UID: %02X %02X %02X %02X\n",$byte1,$byte2,$byte3,$byte4);
         print $line;
      } else {
         print "Error attaching to $curAddy\n";
      }
   }
}

foreach $curAddy (@GPIOs) {
   if ($ValidI2C[$curAddy] ) { # check the Arduinos
      print "\nChecking $DeviceNames->{$curAddy}\n";
      if ($device = attach($curAddy)) {
         my ($byte1,$cnt1) = getI2CdataByte($device,0x00);
         my ($byte2,$cnt2) = getI2CdataByte($device,0x09);
         my ($byte3,$cnt3) = getI2CdataByte($device,0x0A); 
         my $line= sprintf( "GPIO: IODIR: %08b OLAT: %08b GPIO: %08b\n",$byte1,$byte3,$byte2);
         print $line;
      } else {
         print "Error attaching to $curAddy\n";
      }
   }
}

foreach $curAddy (@MPUs) {
   if ($ValidI2C[$curAddy] ) { # check the MPU6050
      print "\nChecking $DeviceNames->{$curAddy}\n"; 
      if ($device = MPU6050->new(0x68)) {
         $device->wakeMPU(4);
         sleep(1);
         my ($AcX,$AcY,$AcZ) = $device->readAccelG();
         my ($tmp,$tmpC,$tmpF) = $device->readTemp();
         my $totG = sqrt($AcX*$AcX + $AcY*$AcY + $AcZ*$AcZ);
         my $line= sprintf( "MPU Data::G: %4.2f Ax: %4.2f Ay: %4.2f Az: %4.2f TempF %4.2f\n", $toG,$AcX,$AcY,$AcZ,$tmpF);
         print $line;
      } else {
         print "Error attaching to $curAddy\n";
      }
   }
}

foreach $curAddy (@OneWires) {
   if ($ValidI2C[$curAddy] ) { # check the One Wire Controllers
      print "\nChecking $DeviceNames->{$curAddy}\n"; 
      if ($device = attach($curAddy)) {
         print "Found 1Wire\n";
      } else {
         print "Error attaching to $curAddy\n";
      }
   }
}


1;
