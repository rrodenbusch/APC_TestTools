#!/usr/bin/perl
###############################################################
#
#
#  i2c_apc_v6
#
#	I2C bus master for the version 6 APC systems
#	    I2C_Device = addy,type,name,optional
#				RelayArd,FBDard,1Wire,GPIO,A2D,UID,MPU
#   	$config->{I2Cdevices} = \@DevicesFnd;
#   	$config->{I2Ctypes} = \@DeviceTypes;
#   	$config->{I2Cversions} = \@DeviceVersions;
#   	$config->{I2Cids} = \@DeviceIDs;
#
#		$config->{I2Cpoll} 	delay between full poll on the bus
#   	
#
###############################################################
use lib "$ENV{HOME}/RPi";
use warnings;
use strict;
use Time::HiRes qw(time sleep usleep);
use RemoteLog;


# File Handles
#	$config->{FH}
#	$config->{LASTFILE}
#	$config->{DELAYS}
#	$config->{LASTTIME}
#	$config->{PREVSTATUS}

use constant {	TEMP 	=> 	0,
				DOOR	=>	1,
				MPU		=> 	2,
				DB		=>	3,
				STATUS	=>	4,
				I2C		=>	5,
				GPIO	=>	6,
				VOLTAGE	=>	7,
				UID		=>  8,
				ARD		=>	9 };


use RPi::I2C;
use RPiConfig;

my $logPrefix = "I2C: ";
my $I2Chome = "$ENV{HOME}/I2C/i2cdata";
my $defI2CqueryTime = 600;	# Check the bus every ten minutes
my $I2CtempTime = 120;		# Check for temps every 2 minutes

my $fdirs = { "MPU"   	=> "$I2Chome/MPU",
			   "dB"   	=> "$I2Chome/dB",
			   "door" 	=> "$I2Chome/door",		
			   "gpio" 	=> "$I2Chome/gpio",			   
			   "volts" 	=> "$I2Chome/voltage",			   
			   "temp" 	=> "$I2Chome/temp",			   
			   "status" => "$I2Chome/status",		   
			   "i2c"  	=> "$I2Chome/i2c",
			   "base"   => "$I2Chome" };
			  
my $TEMPHEADER 	= "epoch,msec,TempCnt,Tmp1,Tmp2";
my $VOLTHEADER 	= "epoch,msec,LoadVolts,SCapVolts";
my $MPUHEADER	= "epoch,msec,AcX,AcY,AcZ,tmp,tmpC,tmpF";
my $DOORHEADER	= "epoch,msec,Doors";
my $DBHEADER	= "epoch,msec,dV1,dV2,Avg1,Avg2,Max1,Max2";
my $I2CHEADER	= "epoch,msec,Addy:Name:ID:Version,..."; 
my $GPIOHEADER  = "epoch,msec,IODIR_0x20,GPIO_0x020,OLAT_GPIO0x20,IODIR_0x21,GPIO_0x21,OLAT_GPIO0x21,IODIR_0x22,GPIO_0x22,OLAT_GPIO0x22,".
							 "IODIR_0x26,GPIO_0x26,OLAT_GPIO0x26,IODIR_0x27,GPIO_0x27,OLAT_GPIO0x27";
my $SYSMONHEADER= "epoch,msec,Doors,TempCnt,Tmp1,Tmp2,LoadVolt,SCapVolt,GPIO,Devices";
	
sub checkDirs {
	my $config = shift;
	my $dir = "$ENV{HOME}/I2C";
	$dir = $config->{I2CDataDir} if (defined($config->{I2CDataDir}));
	if (!(-d $dir) ) {
		`sudo mkdir $dir`;
		`chown pi $dir`;
		`chgrp pi $dir`;
	} else {
		$config->{I2CDataDir} = "$ENV{HOME}/I2C";
		$dir = $config->{I2CDataDir};
		if (!(-d $dir) ) {
			`sudo mkdir $dir`;
			`chown pi $dir`;
			`chgrp pi $dir`;
		}
	}
}	# checkDirs

sub attach {
	my ($config,$addy) = @_;
	my ($device,$retval);

	$device = RPi::I2C->new($addy);
	$device = RPi::I2C->new($addy) unless ($device); 	# one retry on attach
	if ($device) {
		$retval = $device if ( $device->check_device($addy) );		
	} else {
		my $err = $device->file_error();
		$config->{remoteLog}->sendMessage("$logPrefix ERROR,Unable to attach to $addy,$err");
	}
	return ($retval);
}

sub executeI2Ccmd {
	my $config = shift;
	my $line = shift;
	my($addy,$size,$reg,$data) = split(',',$line);
	if (defined($addy) && defined($reg) && defined($data) ) {
		if ( defined($addy) && (my $device = attach($config,$addy)) )  {
			if (uc($size) eq 'WORD') {
				$device->write_word($data,$reg);
			} else {
				$device->write_byte($data,$reg);
			}
		}		
	} else {
		$config->{remoteLog}->sendMessage("$logPrefix ERROR,Bad cmd,$addy,$size,$reg,$data");
	}
}	# executeI2Ccmd

sub checkCMDs {
	my $config = shift;

	my @fnames = glog("$config->{I2CDataDir}/*.*.i2c.cmd");
	@fnames = sort(@fnames);	# sort by time order
	foreach my $fname (@fnames) {
		my ($epoch,$ID) = split(',', $fname);
		if (open(my $fh, "<$fname")) {
			while (my $line = <$fh>) {
				$line =~ s/\R//g;
				executeI2Ccmd($config,$line);
				$config->{remoteLog}->sendMessage("$logPrefix COMMAND,Processed command $epoch $ID $line");			
			} 
		} else {
			$config->{remoteLog}->sendMessage("$logPrefix ERROR, Unable to open $fname,t$!");
		}
	}	# end loop through all command files present
}	# checkCMDs

sub attachMPU {
	my $config = shift;
	my $device;
	my $ready = 0;
	my $addy = 0x68;
	my $maxG = 2;
	my $gBits = 0;
	my $gDivisor = 16384;
	
	if ($device = RPi::I2C->new($addy)) {
		if ($ready = $device->check_device($addy)) {
			$maxG = $config->{maxG} if (defined($config->{maxG})); 
			$config->{maxG} = $maxG unless (defined($config->{maxG}));
			if (($maxG == 2)) {
				$gBits = 0;
				$gDivisor = 16384;
			} elsif ($maxG == 4) {
				$gBits = 0x08;
				$gDivisor = 8192;
			} elsif ($maxG == 8) {
				$gBits = 0x10;
				$gDivisor = 4096;
			} elsif ($maxG == 16) {
				$gBits = 0x18;
				$gDivisor = 2048;
			}
			$config->{I2Cdivisor} = $gDivisor;
			$device->write_byte(0x01,0x6B);  # enable MPU and set clock to PLL w/ x-axis gyro
			# // Configure Gyro and Accelerometer
		    # // Disable FSYNC and set accelerometer and gyro bandwidth to 44 and 42 Hz, respectively; 
		    # // DLPF_CFG = bits 2:0 = 010; this sets the sample rate at 1 kHz for both
			$device->write_byte(0x03,0x1A);  # configuration
			$device->write_byte($gBits,0x1C);  # set accelerometer to +/- 2g
			$config->{gBits} = $gBits;
		} else {
			$config->{COMMERRORS}->[MPU]++;
			undef ($device);
		}
	} else {
		$config->{ATTACHERRORS}->[MPU]++;
	}
	return($device);
}
		
sub checkNibbleChkSum {
	my $value = shift;
	my $retVal = 0xFFFF;
	my $chk  = $value & 0x0f;
	my $nib = ($value & 0xf0) >> 4;
	$chk = $chk & ~$nib;
	$nib = ($value & 0xf00) >> 8;
	$chk = $chk & ~$nib;
	$nib = ($value & 0xf000) >> 12;
	$chk = $chk & ~$nib;
	$retVal = ($value & 0x0FFF) if ($chk == 0);
	return($retVal);
}

sub readGPIO {
	my ($config,$addy) = @_;
	my ($IODIR,$GPIO,$OLAT);
	
    if (my $device = attach($config,$addy)) {
    	$IODIR = $device->read_byte(0x00);
        $GPIO = $device->read_byte(0x09);
        $OLAT = $device->read_byte(0x0A);
   	} else {
		print "Error attaching to $addy\n";
	}

	return($IODIR,$GPIO,$OLAT);
}	# readGPIO

sub getGPIO {
	# Check the FBD IC, then the Arduino if necessary for the door status
	my $config = shift;
	my @GPIObytes;
	my @Empty = ('','','');
	my @tmp;
	
	# Breaker 
	if ( defined($config->{I2Ctype}->{hex("0x20")}) && ($config->{I2Ctype}->{hex("0x20")} eq 'GPIO')) {
		@tmp = readGPIO($config,0x20);
	} else {
		@tmp = @Empty;
	}
	push (@GPIObytes,@tmp);
	
	`gpio -g mode 14 in`;
	`gpio -g write 14 0`;
	# Relay Sense
	if ( defined($config->{I2Ctype}->{hex("0x21")}) && ($config->{I2Ctype}->{hex("0x21")} eq 'GPIO') ) {
		@tmp = readGPIO($config,0x21);
		@tmp = readGPIO($config,0x21) unless (($tmp[0] == 0xFF) && ($tmp[2] == 0));
		if (($tmp[0] != 0xFF) || ($tmp[2] != 0)) {
			print "Error on 0x21, resettting";
			`gpio -g mode 14 out`;
			`gpio -g write 14 0`;
			usleep(3000);
#			if (my $device = attach($config,0x21)) {
#    		 	$device->write_byte(0xFF,0x00);
#    		 	$device->write_byte(0x00,0x0A);
#			}
            `gpio -g mode 14 in`;
		}
	} else {
		@tmp = @Empty;
	}
        `gpio -g mode 14 out`;
        `gpio -g write 14 0`;
	push (@GPIObytes,@tmp);
	
	# Relay Control
	if ( defined($config->{I2Ctype}->{hex("0x22")}) && ($config->{I2Ctype}->{hex("0x22")} eq 'GPIO') ) {
		@tmp = readGPIO($config,0x22);
		@tmp = readGPIO($config,0x22) unless (($tmp[0] == 0xFF) && ($tmp[2] == 0));
		if (($tmp[0] != 0xFF) || ($tmp[2] != 0)) {
			print "Error on 0x22, resettting";
			if (my $device = attach($config,0x22)) {
    		 	$device->write_byte(0xFF,0x00);
    		 	$device->write_byte(0x00,0x0A);
			}
		}
	} else {
		@tmp = @Empty;
	}
	push (@GPIObytes,@tmp);
	
	# FBD Sense
	if ( defined($config->{I2Ctype}->{hex("0x26")}) && ($config->{I2Ctype}->{hex("0x26")} eq 'GPIO') ) {
		@tmp = readGPIO($config,0x26);
	} else {
		@tmp = @Empty;
	}
	push (@GPIObytes,@tmp);
	
	# FBD Ctrl
	if ( defined($config->{I2Ctype}->{hex("0x27")}) && ($config->{I2Ctype}->{hex("0x27")} eq 'GPIO') ) {
		@tmp = readGPIO($config,0x27);
	} else {
		@tmp = @Empty;
	}
	push (@GPIObytes,@tmp);
	
	return (@GPIObytes);
}	# getGPIO

sub trydBs {
	my $device = shift;
	my $register = shift;
	my $config = shift;
	my $retries = shift;
	
	#	dbPause=500
    my ($tmp,$reading);
    $tmp = $device->read_word($register);
    $reading = checkNibbleChkSum($tmp);
    while ( (($reading == 65535) || ($reading == 4095)) && ($retries > 0)) {
       usleep($config->{dbPause});
       $tmp = $device->read_word($register);
       $reading = checkNibbleChkSum($tmp);
       $retries--;
    }
	return($reading,$retries);
}
sub getdBs {
	
	# Check the FBD IC, then the Arduino if necessary for the door status
	#	dbRetries=25
	#	dbGet1=1
	#	dbGet2=1
	#	dbGetMax=1
	#	dbGetPeak=1
	#	dbGetAvg=1
	my $config = shift;
	my ($peak1,$peak2,$avg1,$avg2,$max1,$max2) = (4095,4095,4095,4095,4095,4095);
	# Check the A2D IC first (lower load on Ard)
	#
	#	TBD
	#
	#
#	if ( ( ($config->{I2Cversion}->{hex("0x0F")} & 0xFF) == $config->{I2Cversion}->{hex("0x0F")} ) &&
#		   (hex($config->{I2Cversion}->{hex("0x0F")}) >= hex("0xCD")) ) {
		# Check the Arduino
    	if (my $device = attach($config,0x0F) ) {
         	# Get the sound data
         	my $dbRetries = $config->{dbRetries};
         	($peak1,$dbRetries) = trydBs($device,0x18,$config,$dbRetries) if ($config->{dbGet1} && $config->{dbGetPeak});
         	($peak2,$dbRetries) = trydBs($device,0x19,$config,$dbRetries) if ($config->{dbGet2} && $config->{dbGetPeak});
         	($avg1,$dbRetries) = trydBs($device,0x1A,$config,$dbRetries) if ($config->{dbGet1} && $config->{dbGetAvg});
         	($avg2,$dbRetries) = trydBs($device,0x1B,$config,$dbRetries) if ($config->{dbGet2} && $config->{dbGetAvg});
         	($max1,$dbRetries) = trydBs($device,0x1C,$config,$dbRetries) if ($config->{dbGet1} && $config->{dbGetMax});
         	($max2,$dbRetries) = trydBs($device,0x1D,$config,$dbRetries) if ($config->{dbGet2} && $config->{dbGetMax});
 
         	# Output if data collected  	
			my ($epoch,$msec) = Time::HiRes::gettimeofday();
			my $fh = $config->{FH}->[DB];
			$peak1 = '' if ($peak1 == 4095);
			$peak2 = '' if ($peak2 == 4095);
			$avg1 = '' if ($avg1 == 4095);
			$avg2 = '' if ($avg2 == 4095);
			$max1 = '' if ($max1 == 4095);
			$max2 = '' if ($max2 == 4095);
			print $fh "$epoch,$msec,$peak1,$peak2,$avg1,$avg2,$max1,$max2\n" if defined($fh);	
			return($peak1,$peak2,$avg1,$avg2,$max1,$max2);
    	}
#  	}
    return($peak1,$peak2,$avg1,$avg2,$max1,$max2);
   
}	#	getdBs

sub getTempCnt {
	# Check the FBD IC, then the Arduino if necessary for the door status
	my $config = shift;
	my $devCnt = -1;

	# Check the 1Wire IC first (lower load on Ard)
	#
	#	TBD
	#
	#
#	if ( ( ($config->{I2Cversion}->{hex("0x0F")} & 0xFF) == $config->{I2Cversion}->{hex("0x0F")} ) &&
#	     (hex($config->{I2Cversion}->{hex("0x0F")}) >= hex("0xCC")) ) {
		# Check the Arduino
    	if (my $device = attach($config,0x0F) ) {
         	# Get Temp Count
         	my $word1 = $device->read_word(0x04);	
         	$word1 = $device->read_word(0x04) if ($word1 >= 0xFFFF);	
         	my $databyte = $word1 & 0xFF;
         	my $chkbyte = ($word1 >> 8) & 0xFF;
         	my $chksum = (~$chkbyte) & 0xFF;
         	if ($databyte != $chksum) {
         		$word1 = $device->read_word(0x04);	
         		$word1 = $device->read_word(0x04) if ($word1 >= 0xFFFF);	
         		$databyte = $word1 & 0xFF;
         		$chkbyte = ($word1 >> 8) & 0xFF;
         		$chksum = (~$chkbyte) & 0xFF;
         	}
         	if ($databyte == $chksum) {
	         	$devCnt = $databyte;
	         	$config->{COMMERRORS}->[TEMP]++;
         	}
         } else {
         	$config->{ATTACHERRORS}->[TEMP]++;
         }
#  	}
   return($devCnt);
}

sub getTemps {
	# Check the FBD IC, then the Arduino if necessary for the door status
	my $config = shift;
	my ($temp1, $temp2) = (-2550,-2550);

	# Check the 1Wire IC first (lower load on Ard)
	#
	#	TBD
	#
	#
	my $devCnt = getTempCnt($config);
	
#	if ( ( ($config->{I2Cversion}->{hex("0x0F")} & 0xFF) == $config->{I2Cversion}->{hex("0x0F")} ) && 
#	     ( ($devCnt > 0) && (hex($config->{I2Cversion}->{hex("0x0F")}) >= hex("0xCC")) ) ) {
		my ($word1,$word2,$chksum);
		if (my $device = attach($config,0x0F) ) {
	    	$word1 = $device->read_word(0x06);
	      	$word2 = $device->read_word(0x07);
	      	$chksum = (~$word2 & 0xFFFF);
	      	if ($word1 == $chksum) {
	        	$temp1 = (($word1 & 0xFF00)>>8) |(($word1 & 0x00FF) << 8);
	         	$temp1 = $temp1 / 10.0;
	 		} else {
		    	$word1 = $device->read_word(0x06);
		      	$word2 = $device->read_word(0x07);
	    	  	$chksum = (~$word2 & 0xFFFF);
	 		}	
	      	if ($word1 != $chksum) {
	 			$temp1 = '';
	 			$config->{COMMERRORS}->[TEMP]++;
	 		}
		 	if ($devCnt > 1) {
	    	  	$word1 = $device->read_word(0x08);
	      		$word2 = $device->read_word(0x09);
	      		$chksum = (~$word2 & 0xFFFF);
	      		if ($word1 == $chksum) {
	         		$temp2 = (($word1 & 0xFF00)>>8) |(($word1 & 0x00FF) << 8);
	         		$temp2 = $temp2/10.0;
	      		} else {
	      			$word1 = $device->read_word(0x08);
	      			$word2 = $device->read_word(0x09);
	      			$chksum = (~$word2 & 0xFFFF);
	      		}
	      		if ($word1 != $chksum) {
	      			$temp2 = '';
		 			$config->{COMMERRORS}->[TEMP]++;
	      		}
		 	}
	 	}
	 	$config->{lastTempTime} = time();
#	}
	return($devCnt,$temp1,$temp2);
}  # end getTemps

sub getVolts {
	# Check the FBD IC, then the Arduino if necessary for the door status
	my $config = shift;
	my ($loadVolt,$CapVolt) = (25.5,25.5);
	
#	if (  defined($config->{I2Cversion}->{hex("0x0A")}) &&
#	      ( ($config->{I2Cversion}->{hex("0x0A")} & 0xFF) == $config->{I2Cversion}->{hex("0x0A")} ) &&
#		 (hex($config->{I2Cversion}->{hex("0x0A")}) >= hex("0xAF")) ) {
		# Check the Arduino
		my ($word1,$chkbyte,$databyte,$chksum);
    	if (my $device = attach($config,0x0A) ) {
    	    $word1 = $device->read_word(0x0A);
        	$databyte = $word1 & 0xFF;
        	$chkbyte = ($word1 >> 8) & 0xFF;
	        $chksum = (~$chkbyte) & 0xFF;
        	$loadVolt = $databyte / 10.0 if ($databyte == $chksum);
    	    $word1 = $device->read_word(0x0B);
        	$databyte = $word1 & 0xFF;
        	$chkbyte = ($word1 >> 8) & 0xFF;
	        $chksum = (~$chkbyte) & 0xFF;
        	$CapVolt = $databyte / 10.0 if ($databyte == $chksum);
    	} else {
    		$config->{ATTACHERRORS}->[ARD]++;
    	}  	
#	}
   return($loadVolt,$CapVolt);
}

sub getDoors {
	# Check the FBD IC, then the Arduino if necessary for the door status
	my $config = shift;
	my $doorStatus = 0xFF;

	# Check the GPIO IC first (lower load on Ard)
	#
	#	TBD
	#
	#
#	if ( ( ($config->{I2Cversion}->{hex("0x0F")} & 0xFF) == $config->{I2Cversion}->{hex("0x0F")} ) &&
#	     defined($config->{I2Cversion}->{hex("0x0F")}) && 
#		 (hex($config->{I2Cversion}->{hex("0x0F")}) >= hex("0xCC")) ) {
		# Check the Arduino
		my ($word1,$chkbyte,$databyte,$chksum);
    	if (my $device = attach($config,0x0F) ) {
			# Get Doors
    	    $word1 = $device->read_word(0x03);
        	$databyte = $word1 & 0xFF;
        	$chkbyte = ($word1 >> 8) & 0xFF;
	        $chksum = (~$chkbyte) & 0xFF;
        	$doorStatus = $databyte & 0x03 if ($databyte == $chksum);
    	} else {
    		$config->{COMMERRORS}->[DOOR]++;
    	} 
#   	} else {
#    	$config->{ATTACHERRORS}->[DOOR]++;
#	}
   	return($doorStatus);
}	# getDoors

sub getArdVersion {
	my $config = shift;
	my $curAddy = shift;
	my $version = 'Err';
	if (my $device = attach($config,$curAddy)) {
    	my $byte1 = $device->read_byte(0x00);
        $version = sprintf("0x%02X",$byte1);
   	} else {
    	$config->{ATTACHERRORS}->[ARD]++;
	}
	return($version);
}

sub getUIDid {
	my $config = shift;
	my $curAddy = shift;
	my @UID = (0,0,0,0);
	my $line = 'Err';
	
    if (my $device = attach($config,$curAddy)) {
    	my $byte1 = $device->read_byte(0xFC); 
        my $byte2 = $device->read_byte(0xFD); 
        my $byte3 = $device->read_byte(0xFE); 
        my $byte4 = $device->read_byte(0xFF);
        @UID = ($byte1,$byte2,$byte3,$byte4); 
        $line= sprintf( "%02X %02X %02X %02X",$byte1,$byte2,$byte3,$byte4);
   	} else {
   		$config->{ATTACHERRORS}->[UID]++;
   	}
    return(\@UID,$line);
}

sub queryI2Cbus {
	##
	##	parse the return of i2cdetect
	##
	##      I2C_Device = addy,type,name,optional
	##			RelayArd,FBDArd,1Wire,GPIO,A2D,UID,MPU
	##
	##		$config->{I2Cdevices}
	##		$config->{I2Ctype}
	##		$config->{I2Cname}
	##		$config->{I2Cversion}
	##		$config->{I2Coptional}
	##
	##
	my $config = shift;
	return unless (time() - $config->{LASTTIME}->[I2C] >  $config->{DELAYS}->[I2C] );
	
	my $I2Cconfig   = $config->{I2Cconfig};
	my (@DevicesFnd, %DeviceTypes, %DeviceOptionals, %DeviceNames, %DeviceVersions);
	my $logStr = "$logPrefix Query,";
	my $devCnt = 0;
	my $remoteLog = $config->{remoteLog};

   	my $return = `/usr/sbin/i2cdetect -y 1`;
 	my @lines = split("\n",$return);
  	shift(@lines); # header
   	my $addy = 0x00;
   	foreach my $line (@lines) {
    	my $lineNum = substr($line,0,2);
      	my $offset = 4;
      	my $inc = 3;         
      	for (my $i = 0; $i<16; $i++) {	           			
      		my $myType = "Unknown";           			
      		my $myName = "Unknown";
      		my $myOptional = 1;
         	if ($addy <= 0x7F) {
            	my $curAddy = substr($line,$offset,2);
            	if ( ($curAddy ne "  ") && ($curAddy ne "--")) {
               		my $numAddy = hex("0x".$curAddy);
                	if ($numAddy == $addy) {
                		$devCnt++;
               			push(@DevicesFnd, $addy);
               			my $pAddy = sprintf("0x%02X",$addy);
    	       			$myType = $I2Cconfig->{$addy}->{type} if defined($I2Cconfig->{$addy}->{type});
    	       			$myName = $I2Cconfig->{$addy}->{name} if defined($I2Cconfig->{$addy}->{name});
    	       			$myOptional = $I2Cconfig->{$addy}->{optional} if defined($I2Cconfig->{$addy}->{optional});
        	   			$DeviceTypes{$addy} = $myType;
        	   			$DeviceNames{$addy} = $myName;
    	       			$logStr .= "," if ($devCnt > 1);
    	       			$logStr .= "$pAddy:$myName";
     					if ($myType eq 'UID') {
       						my ($IDarray,$IDstr) = getUIDid($config,$addy);
       						$logStr .= ":$IDstr";
       					} elsif ($myType eq 'RelayArd') {
       						my $version = getArdVersion($config,$addy);
       						$logStr .= ":$version";
       						$DeviceVersions{$addy} = $version;
       					} elsif ($myType eq 'FBDArd') {
       						my $version = getArdVersion($config,$addy);       						
       						$logStr .= ":$version";
       						$DeviceVersions{$addy} = $version;
                		}	       				
               		}
            	}
            	$offset += $inc;
            	$addy++;
    		}
      	}
   	}
   	
 	##  Move to the config data
   	$config->{I2Cdevices} = \@DevicesFnd;
   	$config->{I2Ctype} = \%DeviceTypes;
   	$config->{I2Cname} = \%DeviceNames;
   	$config->{I2Cversion} = \%DeviceVersions;
   	$config->{I2Coptional} = \%DeviceOptionals;
   	$config->{I2Cstatus} = $logStr;
    $config->{LASTTIME}->[I2C]= time();
   	$config->{remoteLog}->sendMessage($logStr);
   	
	return($logStr);
}	# end queryI2Cbus


sub readAccelG {
	my $config = shift;
	my $device = $config->{MPU};
	my $tmp;
	my ($xTries,$yTries,$zTries) = (10,10,10);
	
	$tmp= $device->read_word(0x3B); 	# 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)
	while ( ($tmp == -1) && ($xTries > 0) ) {
		$xTries--;
		usleep(10000);
		$tmp= $device->read_word(0x3B); 	# 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)
	}
	my $AcX = (($tmp << 8) & 0xFF00) | (($tmp >>8) & 0xFF);

  	$tmp = $device->read_word(0x3D); 	# 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
	while ( ($tmp == -1) && ($yTries > 0) ) {
		$yTries--;
		usleep(10000);
		$tmp= $device->read_word(0x3D); 	# 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
	}
	my $AcY = (($tmp << 8) & 0xFF00)  | (($tmp >> 8) & 0xFF);

  	$tmp = $device->read_word(0x3F);	# 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
 	while ( ($tmp == -1) && ($yTries > 0) ) {
		$zTries--;
		usleep(10000);
		$tmp= $device->read_word(0x3F); 	# 0xF (ACCEL_ZOUT_H) & 0x3E (ACCEL_ZOUT_L)
	}
	my $AcZ = (($tmp << 8) & 0xFF00) | (($tmp >> 8) & 0xFF);
	
	my $AX = ($AcX & 0x8000) ? -((~$AcX & 0xffff) + 1) : $AcX;
	my $AY = ($AcY & 0x8000) ? -((~$AcY & 0xffff) + 1) : $AcY;
	my $AZ = ($AcZ & 0x8000) ? -((~$AcZ & 0xffff) + 1) : $AcZ;
	my $gDivisor = $config->{I2Cdivisor};
	$AX = $AX / $gDivisor;
	$AY = $AY / $gDivisor;
	$AZ = $AZ / $gDivisor;
	
	$AX *= $config->{gXcal} if (defined($config->{gXcal}));
	$AY *= $config->{gYcal} if (defined($config->{gYcal}));
	$AZ *= $config->{gZcal} if (defined($config->{gZcal}));
	
	$AX = 10 * $config->{maxG} if ($xTries <= 0);
	$AY = 10 * $config->{maxG} if ($yTries <= 0);
	$AZ = 10 * $config->{maxG} if ($zTries <= 0);

#
#	
#	my $tot = sqrt($AX*$AX + $AY*$AY + $AZ*$AZ);
#	my $line = sprintf("%.2f %.2f %.2f %.2f",$tot,$AX,$AY,$AZ);
#	print "$line\n";
	return($AX,$AY,$AZ);
}



sub readTemp {
	my $config = shift;
	my $device = $config->{MPU};
	my $tmp1 = $device->read_word(0x41);		# 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
	$tmp1 = $device->read_word(0x41) if ($tmp1 == 0xFFFF);		# 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
	my $Tmp = (($tmp1 << 8 ) & 0xFF00) | ( ($tmp1 >> 8) & 0xFF);
	my $temp = ($Tmp & 0x8000) ? -((~$Tmp & 0xffff) + 1) : $Tmp; 
	my $TmpC = $temp/340.0 + 36.53;
	my $TmpF = $TmpC * 9.0/5.0 + 32.0;
	return($Tmp,$TmpC,$TmpF);
}

sub sampleMPU {
	my $config = shift;
	my $device = $config->{MPU};
	my ($epoch,$msec,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF);
	my $Mtries = 10;

	
	if ( defined($config->{I2Ctype}->{hex("0x68")}) && ($config->{I2Ctype}->{hex("0x68")} eq 'MPU') ){
		while (!defined($config->{MPU}) && ($Mtries > 0)) {
			usleep(1000);  # 1 msec pause
			$config->{remoteLog}->sendMessage("I2C: MPU busy - retry") if ($Mtries == 10);
			$Mtries--;
			$config->{MPU} = attachMPU($config) unless defined($config->{MPU});
		}
		my $device = $config->{MPU};
		if (defined($device)) {
			my $tries = 10;
			my $bits = $device->read_byte(0x1C);
			while ( ( ($bits == -1) || ($bits != $config->{gBits}) ) && ($tries > 0) ) {
				my $bitStr = sprintf("%08b",$bits);
				$bitStr = "-1" if ($bits == -1);
				$config->{remoteLog}->sendMessage("I2C: MPU reset - restart:$bitStr") if ($tries == 10);					
				usleep(1000);
				if ($bits == -1) {
					$bits = $device->read_byte(0x1C);
				} else {
					$device = attachMPU($config);
					$bits = $device->read_byte(0x1C) if defined($device);
				}
				$tries--;
			}
			if ($bits == $config->{gBits}) {			
				($AcX,$AcY,$AcZ) = (10*$config->{maxG},10*$config->{maxG},10*$config->{maxG});
				my ($epoch,$msec,$tmp,$tmpC,$tmpF,$tot);
				$tot = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
				while ((abs($AcX) >= 2* $config->{maxG}) || (abs($AcY) >= 2*$config->{maxG}) ||
						(abs($AcZ) >= 2* $config->{maxG}) ) {
					($epoch,$msec) = Time::HiRes::gettimeofday();
					($AcX,$AcY,$AcZ) = readAccelG($config);
					($tmp,$tmpC,$tmpF) = readTemp($config);
					$tot = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
				}
				my $fh = $config->{FH}->[MPU];	
				print $fh "$epoch,$msec,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF,$tot\n" if defined($fh);		
			} else {
				$config->{remoteLog}->sendMessage("I2C:MPU busy 2, retrying Sample") if (defined($config->{remoteLog}));;				
			}
		} else {
			$config->{remoteLog}->sendMessage("I2C:MPU busy, retrying Sample") if (defined($config->{remoteLog}));;
		}
	}
	return ($epoch,$msec,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF);
}

sub openFile {
	my ($config,$fname) = @_;
	my $fh;
	
	if (!open($fh, ">$fname")) {
		$config->{remoteLog}->sendMessage("$logPrefix ERROR, Unable to to open $fname");		
	} else {
		# Set for auto flush
		my $old_fh = select($fh);
		$| = 1;
		select($old_fh);
	}
	return($fh);	
}	# openFile

sub openFiles {
	my	$config = shift;
	my ($epoch,$msec) = Time::HiRes::gettimeofday();
	
	my $fh = $config->{FH}->[DB];
	close($fh) if defined($fh);
    $fh	= openFile($config, "$fdirs->{dB}/$epoch.dB.csv");
    $config->{FH}->[DB] = $fh;
	print $fh "$DBHEADER\n" if defined($fh);	
    
	$fh = $config->{FH}->[DOOR];
	close($fh) if defined($fh);
	$fh	= openFile($config, "$fdirs->{door}/$epoch.Doors.csv");
    $config->{FH}->[DOOR] = $fh;
	print $fh "$DOORHEADER\n" if defined($fh);	
		
    
	$fh = $config->{FH}->[GPIO];
	close($fh) if defined($fh);
	$fh	= openFile($config, "$fdirs->{gpio}/$epoch.gpio.csv");
    $config->{FH}->[GPIO] = $fh;
	print $fh "$GPIOHEADER\n" if defined($fh);	
		
    $fh = $config->{FH}->[MPU];
	close($fh) if defined($fh);
    $fh = openFile($config, "$fdirs->{MPU}/$epoch.MPU.csv");
    $config->{FH}->[MPU] = $fh;
	print $fh "$MPUHEADER\n" if defined($fh);	
	
    $fh = $config->{FH}->[TEMP];
	close($fh) if defined($fh);
	$fh = openFile($config, "$fdirs->{temp}/$epoch.Temp.csv");
    $config->{FH}->[TEMP] = $fh;
	print $fh "$TEMPHEADER\n" if defined($fh);	
	
    $fh = $config->{FH}->[I2C];
	close($fh) if defined($fh);
	$fh	= openFile($config, "$fdirs->{i2c}/$epoch.I2Cstatus.csv");
    $config->{FH}->[I2C] = $fh;
	print $fh  "$I2CHEADER\n" if defined($fh);	
	
    $fh = $config->{FH}->[VOLTAGE];
	close($fh) if defined($fh);
	$fh	= openFile($config, "$fdirs->{volts}/$epoch.Voltage.csv");
    $config->{FH}->[VOLTAGE] = $fh;
	print $fh  "$VOLTHEADER\n" if defined($fh);	
	
    $fh = $config->{FH}->[STATUS];
	close($fh) if defined($fh);
	$fh	= openFile($config, "$fdirs->{status}/$epoch.SystemStatus.csv");
    $config->{FH}->[STATUS] = $fh;
	print $fh  "$SYSMONHEADER\n" if defined($fh);
	
	$fh = $config->{CURSTATUSFILE};
	close($fh) if defined($fh);
	`mv $fdirs->{base}/SystemStatus.csv $fdirs->{base}/SystemStatus.old`;
	$fh	= openFile($config, "$fdirs->{base}/SystemStatus.csv");
    $config->{CURSTATUSFILE} = $fh;
	print $fh  "$SYSMONHEADER\n" if defined($fh);
	
}	# openFiles

sub initialize{
	my $value = shift;
	my @ret;
	foreach my $idx (@_) {
		$ret[$idx] = $value;
	}
	return(\@ret);
}	# initialize

sub outputStatus{
	my ($config,$I2Cdevices,$tempSample,$doorStatus,$GPIObytes,$Voltages) = @_;
	my $newStatus = 0;
	my $prevStatus = $config->{PREVSTATUS};
	my ($epoch,$msec) = Time::HiRes::gettimeofday();

	## I2C devices
	if (defined($I2Cdevices) && ($I2Cdevices ne $prevStatus->[I2C]) ) {
		$newStatus = 1;
		$prevStatus->[I2C] = $I2Cdevices;
		my $fh = $config->{FH}->[I2C];
		print $fh "$epoch,$msec,$I2Cdevices\n"  if defined($fh);	
	}
	
	## Door opened or closed
	if ( defined($doorStatus) && ($doorStatus ne $prevStatus->[DOOR])) {
		$newStatus = 1;
		$prevStatus->[DOOR] = $doorStatus;
		my $fh = $config->{FH}->[DOOR];
		$config->{remoteLog}->sendMessage("$logPrefix Doors: Door Status $doorStatus");
		print $fh "$epoch,$msec,$doorStatus\n" if defined($fh);	
	}
	
	## Temp changed
	my $tempStatus = join(',',@{$tempSample});
	if ($tempStatus ne $prevStatus->[TEMP]) {
		$newStatus = 1;
		$prevStatus->[TEMP] = $tempStatus;	
		my $fh = $config->{FH}->[TEMP];
		print $fh "$epoch,$msec,$tempStatus\n" if defined($fh);		
	}
	
	## GPIO devices
	my $GPIOstatus;
	foreach my $curByte (@{$GPIObytes}) {
		$GPIOstatus .= ',';
		$GPIOstatus .= sprintf("%08b",$curByte) if (defined($curByte) && ($curByte ne ''));
	}
	if ($GPIOstatus ne $prevStatus->[GPIO]) {
		$newStatus = 1;
		$prevStatus->[GPIO] = $GPIOstatus;	
		my $fh = $config->{FH}->[GPIO];
		print $fh "$epoch,$msec$GPIOstatus\n" if defined($fh);		
	}
		
	## Voltages
	my $VoltStatus = join(',',@{$Voltages});
	if ($VoltStatus ne $prevStatus->[VOLTAGE]) {
		$newStatus = 1;
		$prevStatus->[VOLTAGE] = $VoltStatus;
		my $fh = $config->{FH}->[VOLTAGE];
		print $fh "$epoch,$msec,$VoltStatus\n" if defined($fh);			
	}
	
	if ( ($newStatus != 0) || !defined($config->{LastStatusTime}) ||
	     (time() - $config->{LastStatusTime} > 30)) {
		$config->{LastStatusTime} = time();
		$doorStatus = '' unless defined($doorStatus);
		my $statusLine = "$epoch,$msec,$doorStatus,$tempStatus$GPIOstatus,$VoltStatus,$I2Cdevices";
		# 0:epoch,1:msec,2:doorBits,3:tmpCnt,4:tmp1,5:tmp2,
		#    6:BrkrIODIR,7:BrkrGPIO,8:BrkrOLAT,
		#    9:RelaySnsIODIR,10:RelaySnsGPIO,11:RelaySnsOLAT,12:RelayCtrlIODIR,13:RelayCtrlGPIO,14:RelayCtrlOLAT,
		#   15:FBDIODIR,16:FBDGPIO,17:FBDOLAT,18: FBDCtrlIODIR, 19: FBDCtrlGPIO, 20:FBDCtrl,OLAT
		#	21:Load, 22:SCap, 23:I2C: Query,@devices
		my $fh = $config->{FH}->[STATUS];
		print $fh "$statusLine\n" if defined($fh);
		$fh = $config->{CURSTATUSFILE};
		print $fh "$statusLine\n" if defined($fh);
		
	}
}	# end outputStatus

sub setupConfig {
	my $config = shift;
	$config->{I2Cpoll} = $defI2CqueryTime unless defined($config->{I2Cpoll});
	$config->{I2Ctempdelay} = $I2CtempTime unless defined($config->{I2Ctempdelay});
	
	# NO NETWORK MAPPING
#	$config->mapNetwork();
	my $remoteLog = $config->{remoteLog};
	my $myRole = $config->{myRole};
#	my $myMAC = $config->{myMAC};
#	my $routerMAC = $config->{routerMAC};
#	my $UID = "$routerMAC::$myMAC";
#	$UID =~ s/://g;
#	$config->{UID} = $UID;
#	$remoteLog->sendMessage("$logPrefix UID,MAC: $myMAC :: Router: $routerMAC\n");
	$config->{MPU} = attachMPU($config);
	$config->{lastTempTime} = 0;
	
	$config->{LASTFILE} = [];
	$config->{LASTTIME} = [];
	$config->{DELAYS} = [];
	$config->{PREVSTATUS} = [];
	
	$config->{LASTFILE} = initialize(0,TEMP,DOOR,MPU,DB,STATUS,I2C,GPIO,VOLTAGE,UID,ARD);
	$config->{LASTTIME} = initialize(0,TEMP,DOOR,MPU,DB,STATUS,I2C,GPIO,VOLTAGE,UID,ARD);
	$config->{DELAYS}   = initialize(30,TEMP,DOOR,MPU,DB,STATUS,I2C,GPIO,VOLTAGE,UID,ARD);
	$config->{PREVSTATUS} = initialize('-1',TEMP,DOOR,MPU,DB,STATUS,I2C,GPIO,VOLTAGE,UID,ARD);
	$config->{COMMERRORS} =  initialize(0,TEMP,DOOR,MPU,DB,STATUS,I2C,GPIO,VOLTAGE,UID,ARD);
	$config->{ATTACHERRORS} =  initialize(0,TEMP,DOOR,MPU,DB,STATUS,I2C,GPIO,VOLTAGE,UID,ARD);
	
	$config->{I2C_sleep} = 0 unless defined($config->{I2C_sleep});
	
	# Over ride any delays from file
	my ($dbRetries,$dbPause,$dbGet1,$dbGet2,$dbGetMax,$dbGetPeak,$dbGetAvg) = (25,500,1,1,1,1,1);
	$config->{dbRetries} = $dbRetries unless defined($config->{dbRetries});
	$config->{dbPause} = $dbPause unless defined($config->{dbPause});
	$config->{dbGet1} = $dbGet1 unless defined($config->{dbGet1});
	$config->{dbGet2} = $dbGet2 unless defined($config->{dbGet2});
	$config->{dbGetMax} = $dbGetMax unless defined($config->{dbGetMax});
	$config->{dbGetPeak} = $dbGetPeak unless defined($config->{dbGetPeak});
	$config->{dbGetAvg} = $dbGetAvg unless defined($config->{dbGetAvg});
	
	return($config);
}	# setupConfig

sub processSignals{
	my $config = shift;
	if ( $config->getSig('HUP')) {
 		$config->resetSig('HUP');
 		$config->mapNetwork();
 		$config->{remoteLog}->sendMessage("$logPrefix HUP, File rotation");
 		openFiles($config);
 	}	
 	if ( $config->getSig('USR1')) {
 		$config->resetSig('USR1');
 		$config->renew();
 		$config->{remoteLog}->sendMessage("$logPrefix USR1, Refresh config");
 	}
 	if ( $config->getSig('USR2')) {
 		$config->resetSig('USR2');
 		$config->{remoteLog}->sendMessage("$logPrefix USR2, Bus refresh");
 		$config->{LASTTIME}->[I2C] = 0;
 	}
}	#	processSignals

`gpio -g mode 14 out`;
`gpio -g write 14 0`;
my 	($RelayIODIR,$RelayGPIO,$RelayOLAT,$FBDIODIR,$FBDGPIO,$FBDOLAT,$BrkrIODIR,$BrkrGPIO,$BrkrOLAT);
my 	($doorStatus,$tmpCnt,$tmp1,$tmp2);
my 	($peak1,$peak2,$avg1,$avg2,$max1,$max2);
my 	($loadVolt,$CapVolt,$prevLoad,$prevCap) = (0,0,0,0);
my  ($prevTmpCnt,$prevTmp1,$prevTmp2) = (-1,'','');
my 	($AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF);
my  ($dBFH,$tempFH,$doorFH,$MPUFH,$I2Cdevices,$epoch,$MPUepoch,$msec,$LastI2Cdevices);
my 	(@dBsample,@tempSample,@MPUsample,@GPIObytes,@I2Cbus,@voltArray);

my $startEpoch = time();
my $config = RPiConfig->new();
$config->{logIP} = "$config->{subnet}.231";
$config->{remoteLog} = RemoteLog->new($config);
$config->{remoteLog}->{logIP} = "$config->{subnet}.231";
setupConfig($config);
openFiles($config);
my ($NUCepoch,$NVNepoch,$NUCvolt,$NVNvolt) = (0,0,0,0);

while( $config->getSig('ABRT') == 0) {
	processSignals($config);
	my $epoch = time(); 	

	@voltArray = getVolts($config);
	# Filter out errors
	if ( ( ($voltArray[0] < 25) && (abs($voltArray[0] - $prevLoad) > 0.15) ) ||
	     ( ($voltArray[1] < 25) && (abs($voltArray[1] - $prevCap) > 0.15) ) ) {
		$loadVolt = $voltArray[0]; 
		$CapVolt = $voltArray[1];
	 	$prevCap = $CapVolt;
	 	$prevLoad = $voltArray[0];
	} else {
		$loadVolt = $prevLoad;
		$CapVolt = $prevCap;
	}
	@voltArray = ($loadVolt,$CapVolt);

	my ($IO,$GPIO,$OLAT) = readGPIO($config,0x21);
	my ($NVNon, $NUCon) = ( ($GPIO & 0x40), ($GPIO & 0x08) );
	$NVNepoch = $epoch if ($NVNvolt == 0);
	$NVNepoch = $epoch if ($NUCvolt == 0);
	$NVNvolt = $CapVolt if ( ($NVNvolt == 0) && ($NVNon) );
	$NUCvolt = $CapVolt if ( ($NUCvolt == 0) && ($NUCon) );

        my $bits = sprintf("%08b", $GPIO);
	print ("$epoch,$CapVolt,$NVNon,$NUCon,$bits,$GPIO\n");	
	sleep (1);
	
}
   warn "NVN on @ $NVNvolt\nNUC on @ $NUCvolt\n";

1;
