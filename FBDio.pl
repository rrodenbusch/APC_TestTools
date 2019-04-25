#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";
my $FBDaddy = 0x0F;

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
	my $i2cAddy = $_[0];
   	my $cnt = 0;
   	my ($word1,$chkbyte,$databyte,$chksum);
   	my $Dok = 0;
   	my ($door1,$door2,$door1str,$door2str);
   	do {
      $cnt ++;
      if (my $device = attach($i2cAddy) ) {
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

sub getTempCnt {
	my $i2cAddy = $_[0];
	my $cnt = 0;
   	my $CntOk = 0;
   	my ($device,$word1,$databyte,$chkbyte,$chksum,$str);
   	do {
      $cnt ++;
      if ($device = attach($i2cAddy) ) {
         # Get Temp Count
         $word1 = $device->read_word(0x04);
         $databyte = $word1 & 0xFF;
         $chkbyte = ($word1 >> 8) & 0xFF;
         $chksum = (~$chkbyte) & 0xFF;
         if ($databyte == $chksum) {
            $str = sprintf("Num temps %02X %02X  try:%d",$databyte,$chkbyte,$cnt);
            print "Num Temps $str\n";
            $CntOk = 1 
         }
      } else {
         sleep(0);
   #      print "Bad attach try:$cnt\n";
      }
   } while ($CntOk == 0);
   return($databyte);
}

sub getTemp {
	my ($i2cAddy,$tempCnt) = @_;
	my ($temp1, $temp2) = (-2550,-2550);
	my $Tok = 0;
	my $cnt = 0;
	my ($word1,$word2,$chksum,$str);
	do {
	   $cnt ++;
	   if (my $device = attach($i2cAddy) ) {
	      # Get Version
	      $word1 = $device->read_word(0x06);
	      $word2 = $device->read_word(0x07);
	      $chksum = (~$word2 & 0xFFFF);
	      if ($word1 == $chksum) {
	         $temp1 = (($word1 & 0xFF00)>>8) |(($word1 & 0x00FF) << 8);
	         $temp1 = $temp1 / 10.0;
	         $Tok = 1 
	      }
	      $word1 = $device->read_word(0x08);
	      $word2 = $device->read_word(0x09);
	      $chksum = (~$word2 & 0xFFFF);
	      if ($word1 == $chksum) {
	         $temp2 = (($word1 & 0xFF00)>>8) |(($word1 & 0x00FF) << 8);
	         $temp2 = $temp2/10.0;
	         $Tok = 1 
	      }
	   } else {
	      sleep(0);
	   }
	} while ($Tok == 0);
	$str = sprintf("T1 %04.1f T2 %04.1f Count %d",$temp1,$temp2,$tempCnt);
	print "$str\n";
	return($word1,$word2,$cnt);
}  # end getTemp

my ($cmd,$addy,$register,$data) = @ARGV;
$addy = hex $FBDaddy if (defined($FBDaddy));
$register = hex $register if (defined($register));
$data = hex $data if (defined($data));
my ($cnt,$device,$Vok,$Dok);
$Dok = 0;
$Vok = 0;
$cnt = 0;
my ($str,$word1,$chkbyte,$databyte,$chksum);

do {
   $cnt ++;
   if ($device = attach($addy) ) {
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

my $epoch = time();
my ($tempData,$tempSum,$tempCnt);
$tempCnt = getTempCnt($addy);
($tempData,$tempSum,$tempCnt) = getTemp($addy,$tempCnt) if ($tempCnt > 0);
my $tempTime = time();
my ($door1,$door2) = getDoors($addy);
my ($prevDoor1,$prevDoor2) = ($door1,$door2);
$str = sprintf("%02X %02X",$databyte,$chkbyte);
print "$door1  $door2 $str \n";
while (1) {
   ######### Check the temp ##############
   if (time() - $tempTime > 20) {  # get temp every 20 seconds
      $tempCnt = getTempCnt($addy);
      ($tempData,$tempSum,$tempCnt) = getTemp($addy,$tempCnt) if ($tempCnt > 0);
      $tempTime = time();
   }
   #########  Check the doors ############
   ($door1,$door2,$databyte,$chkbyte) = getDoors($addy);
   if ( ($door1 ne $prevDoor1) || ($door2 ne $prevDoor2)) {
      print "$door1  $door2      $str\n";
      ($prevDoor1,$prevDoor2) = ($door1,$door2);
   }
}

1;
