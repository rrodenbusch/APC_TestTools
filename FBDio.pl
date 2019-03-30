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

sub getDoors {
   my $cnt = 0;
   my ($word1,$chkbyte,$databyte,$chksum);
   my $Dok = 0;
   my ($door1,$door2,$door1str,$door2str);
   do {
      $cnt ++;
      if (my $device = attach(0x0f) ) {
         # Get Doors
         $word1 = $device->read_word(0x03);
         $databyte = $word1 & 0xFF;
         $chkbyte = ($word1 >> 8) & 0xFF;
         $chksum = (~$chkbyte) & 0xFF;
         $door1 = ($databyte & 0x01) & 0xFF;
         $door2 = ($databyte & 0x02) & 0xFF;
         if ($databyte == $chksum) {
            $door1str = "closed";
            $door1str = "opened" if $door1 == 0;
            $door2str = "closed";
            $door2str = "opened" if $door2 == 0;
            $Dok = 1; 
         }
      } else {
         sleep(0);
 #        print "Bad attach try:$cnt\n";
      }
   } while ($Dok == 0);
   return($door1str,$door2str,$databyte,$chkbyte);
}

sub getTemp {
my $Tok = 0;
my $cnt = 0;
my ($word1,$word2,$chksum,$str);
do {
   $cnt ++;
   if (my $device = attach(0x0f) ) {
      # Get Version
      $word1 = $device->read_word(0x06);
      $word2 = $device->read_word(0x07);
      $chksum = ~$word2;
      #if ($word1 == $chksum) {
         $str = sprintf("Temp %d %04X %04X  try:%d",$word1, $word1,$word2,$chksum,$cnt);
         print "$str\n";
         $Tok = 1 
      #}
   } else {
      sleep(1);
#      print "Bad attach try:$cnt\n";
   }
} while ($Tok == 0);
   return($word1,$word2,$cnt);
}  # end getTemp

my ($cmd,$addy,$register,$data) = @ARGV;
$addy = hex $addy if (defined($addy));
$register = hex $register if (defined($register));
$data = hex $data if (defined($data));
my ($cnt,$device,$Vok,$Dok);
$Dok = 0;
$Vok = 0;
$cnt = 0;
my ($str,$word1,$chkbyte,$databyte,$chksum);

do {
   $cnt ++;
   if ($device = attach(0x0f) ) {
      # Get Version
      $word1 = $device->read_word(0x00);
      $databyte = $word1 & 0xFF;
      $chkbyte = ($word1 >> 8) & 0xFF;
      $chksum = (~$chkbyte) & 0xFF;
      if ($databyte == $chksum) {
         $str = sprintf("Version %02X %02X  try:%d",$databyte,$chkbyte,$cnt);
         print "Version $str\n";
         $Vok = 1 
      }
   } else {
      sleep(0);
#      print "Bad attach try:$cnt\n";
   }
} while ($Vok == 0);

while (1) {
   my ($tempData,$tempSum,$tempCnt) = getTemp();
   }

my ($door1,$door2) = getDoors();
$str = sprintf("%02X %02X",$databyte,$chkbyte);
print "$door1  $door2 $str \n";
my ($prevDoor1,$prevDoor2) = ($door1,$door2);
while (1) { 
   ($door1,$door2,$databyte,$chkbyte) = getDoors();
   $str = sprintf("%02X %02X",$databyte,$chkbyte);
   if ( ($door1 ne $prevDoor1) || ($door2 ne $prevDoor2)) {
      print "$door1  $door2\n";
      ($prevDoor1,$prevDoor2) = ($door1,$door2);
   }
}
1;
