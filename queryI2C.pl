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

sub queryI2Cbus {
   my @ValidI2C;
   
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
            print "Chekcing $curAddy\n");
               my $numAddy = hex("0x".$curAddy);
               $ValidI2C[$addy] = ($numAddy == $addy);
               $offset += $inc;
               $addy++;
            }
         }
      }
   }

   for (my $i =0; $i<=0x7F; $i++) {
      if ($ValidI2C[$i]) {
         my $str = sprintf("Found %02X\n",$i);
         print $str;
      }
   }
   return(\@ValidI2C);
}

queryI2Cbus();

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
} elsif (defined($cmd) && ($cmd eq 'readword')) {
	if ($device = attach($addy)) {
		my $word1 = getI2CdataWord($device,$register);
		#my $byte1 = $device->read_word($register);
		my $str = sprintf("%04X %06d %16b" ,$word1 & 0xFFFF,
				$word1 & 0xFFFF, $word1 & 0xFFFF );
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
}
elsif (defined($cmd) && ($cmd eq 'write') ) {
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
} else {
	warn "Usage I2Cio.pl [read|write] addy data";
}


1;
