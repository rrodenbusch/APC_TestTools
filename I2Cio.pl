#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/RPi";
use Time::HiRes qw(time sleep usleep);

use RPi::I2C;


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

sub readnibble {
   my ($dev,$reg) = @_;
   my $retval = -1;
   my $retries = 0;
   $dev = hex($dev) if defined($dev);
   $reg = hex($reg) if defined($reg);
   
   if (my $device = attach($dev)) {
      while ( ($retval == -1) && ($retries < 5) ) {
         $retval = $device->read_byte($reg);
         if ($retval == -1) {
            $retries++;
            sleep(0.20) if ($retries < 5);
         }
         $retries++;
      }
   } else {
      die "Unable to attach to $dev";
   }
   die "Comm Error $reg" if ($retries >= 5);
   outputNibble($dev,$reg,$retval);
   return($retval);
}


sub readbyte {
   my ($dev,$reg) = @_;
   my $retval = -1;
   my $retries = 0;
   $dev = hex($dev) if defined($dev);
   $reg = hex($reg) if defined($reg);
   
   if (my $device = attach($dev)) {
      while ( ($retval == -1) && ($retries < 5) ) {
         $retval = $device->read_byte($reg);
         if ($retval == -1) {
            $retries++;
            sleep(0.20) if ($retries < 5);
         }
         $retries++;
      }
   } else {
      die "Unable to attach to $dev";
   }
   die "Comm Error $reg" if ($retries >= 5);
   outputByte($dev,$reg,$retval);
   return($retval);
}

sub writebyte {
   my ($devstr,$regstr,$valstr) = @_;
   my $retval = -1;
   my $retries = 0;
   my $dev = hex($devstr) if defined($devstr);
   my $reg = hex($regstr) if defined($regstr);
   my $val = hex($valstr) if defined($valstr);
   
   print "Was: ";
   readbyte($devstr,$regstr);
   if (my $device = attach($dev)) {
      while ( ($retval == -1) && ($retries < 5) ) {
         $retval = $device->write_byte($val,$reg);
         if ($retval == -1) {
            $retries++;
            sleep(0.20) if ($retries < 5);
         }
         $retries++;
      }
   } else {
      die "Unable to attach to $dev";
   }
   die "Comm Error $reg" if ($retries >= 5);
   print " Is: ";
   readbyte($devstr,$regstr);
   return($retval);
}

sub readword {
   my ($dev,$reg) = @_;
   my $retval = -1;
   my $retries = 0;
   $dev = hex($dev) if defined($dev);
   $reg = hex($reg) if defined($reg);
   
   if (my $device = attach($dev)) {
      while ( ($retval == -1) && ($retries < 5) ) {
         $retval = $device->read_word($reg);
         if ($retval == -1) {
            $retries++;
            sleep(0.20) if ($retries < 5);
         }
         $retries++;
      }
   } else {
      die "Unable to attach to $dev";
   }
   die "Comm Error $reg" if ($retries >= 5);
   outputWord($dev,$reg,$retval);
   return($retval);
}

sub writeword {
   my ($devstr,$regstr,$valstr) = @_;
   my $retval = -1;
   my $retries = 0;
   my $dev = hex($devstr) if defined($devstr);
   my $reg = hex($regstr) if defined($regstr);
   my $val = hex($valstr) if defined($valstr);
   
   print "Was: ";
   readword($devstr,$regstr);
   if (my $device = attach($dev)) {
      while ( ($retval == -1) && ($retries < 5) ) {
         $retval = $device->write_word($val,$reg);
         if ($retval == -1) {
            $retries++;
            sleep(0.20) if ($retries < 5);
         }
         $retries++;
      }
   } else {
      die "Unable to attach to $dev";
   }
   die "Comm Error $reg" if ($retries >= 5);
   print " Is: ";
   readword($devstr,$regstr);
   return($retval);
}

sub outputByte {
   my ($dev,$reg,$retval) = @_;
   my $str = sprintf("%02X %02X %03d %02X %08b" ,$dev,$reg,$retval,$retval,$retval);
   print "$str\n";
}

sub outputWord {
   my ($dev,$reg,$retval) = @_;
   my $str = sprintf("%02X %02X %08d %04X %016b" ,$dev,$reg,$retval,$retval,$retval);
   print "$str\n";
}


my $cmd = shift(@ARGV);
die "No command provided" unless defined($cmd);
if ( ($cmd eq 'read') || ($cmd eq 'readbyte') ) {
   my $retval = readbyte(@ARGV);
} elsif ( ($cmd eq 'write') || ($cmd eq 'writebyte' ) ) {
   writebyte(@ARGV);
} elsif ($cmd eq 'readword') {
   readword(@ARGV);
} elsif ($cmd eq 'readnibbles') {
   readnibbles(@ARGV);
} elsif ($cmd eq 'writeword') {
   writeword(@ARGV);
} else {
   die "Invalid cmd $cmd"
}


#} elsif (defined($cmd) && ($cmd eq 'readwordchk')) {
#	if ($device = attach($addy)) {
#		my $cnt = 0;
#		my ($word1,$retries1) = getI2CdataWord($device,$register);
#		my ($word2,$retries2) = getI2CdataWord($device,$register+1);
#		my $totTries = $retries1 + $retries2;
#		while (~$word1 != $word2) {
#			$cnt++;
#			my $str2 = sprintf("Chksum Error $cnt %04X %04X\n",$word1,$word2);
#			usleep(50);
#			($word1,$retries1) = getI2CdataWord($device,$register);
#			($word2,$retries2) = getI2CdataWord($device,$register+1);
#			$totTries += $retries1 + $retries2;
#		}
#		my $str = sprintf("%04X %06d %16b @%02d" ,$word1 & 0xFFFF,
#				$word1 & 0xFFFF, $word1 & 0xFFFF, $totTries );
#		print "Word $word1 :: $str\n";
#	} else {
#		warn "Device $addy NOT READY\n" unless ($device = attach($addy));
#	}	




1;
