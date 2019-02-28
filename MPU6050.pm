package MPU6050;
use lib "$ENV{HOME}/RPi";
##########################################
#
#  Basic Socket configuration for NVF
#
##########################################
use strict;
use warnings;
use RPi::I2C;

sub readI2Cbyte {
	my ($self,$timeout) = @_;
	my ($data,$retData);
	my $cnt = 0;
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;
	my $device = $self->{MPU};

	do {  # wait for return a max of one second
		$data = $device->read();
		Time::HiRes::usleep($delaytics) if (!defined($data) || ($data == -1)); # milliseconds
	} while ( (!defined($data)  || ($data == -1)) && ($cnt++ < $loopcnt) );
	$retData = $data if ($data != -1);  # return undefined in no return values available
	return ($retData,$cnt);
}
sub readI2Cword {
	my ($self,$cmd,$timeout) = @_;
	my ($data,$retData,@bytes);
	my $cnt = 0;
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;
	my $device = $self->{MPU};

	do {  # wait for return a max of one second
		@bytes = $device->read_block(2,$cmd);
		Time::HiRes::usleep($delaytics) if (!defined($bytes[0])); # milliseconds
	} while ( (!defined($bytes[0])) && ($cnt++ < $loopcnt) );
	return (@bytes);
}
sub getI2CdataByte {
	my ($self,$cmd,$timeout) = @_;
	$timeout = 1000 if !defined($timeout);  # default time is 1 second
	my $device = $self->{MPU};
	$device->write($cmd);
	my ($byte1,$cnt) = $self->readI2Cbyte($timeout);
	return($byte1,$cnt);
}
sub getI2CdataWord {
	my ($self,$cmd,$timeout) = @_;
	my @bytes;
	$timeout = 1000 if !defined($timeout);  # default time is 1 second
	@bytes = $self->readI2Cword($cmd,$timeout);
	my $retVal = (($bytes[0] & 0xFF) << 8) | ($bytes[1] & 0xFF);
	return($retVal);
}

sub readRawGyro {
	my $self = shift;
	
	my $GyX= $self->getI2CdataWord(0x43);		# 0x43 (GYRO_XOUT_H) & 0x44 (GYRO_XOUT_L)
  	my $GyY= $self->getI2CdataWord(0x45);		# 0x45 (GYRO_YOUT_H) & 0x46 (GYRO_YOUT_L)
  	my $GyZ= $self->getI2CdataWord(0x47);		# 0x47 (GYRO_ZOUT_H) & 0x48 (GYRO_ZOUT_L)
	return($GyX,$GyY,$GyZ);
}
sub readTemp {
	my $self = shift;
	my $Tmp= $self->getI2CdataWord(0x41);		# 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
	my $temp = ($Tmp & 0x8000) ? -((~$Tmp & 0xffff) + 1) : $Tmp; 
	my $TmpC = $temp/340.0 + 36.53;
	my $TmpF = $TmpC * 9.0/5.0 + 32.0;
	return($Tmp,$TmpC,$TmpF);
}

sub readRawTemp {
	my $self = shift;
	my $Tmp= $self->getI2CdataWord(0x41);		# 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
	return($Tmp);
}
sub readAccelRaw {
	my $self = shift;
	
  	my $AcX= $self->getI2CdataWord(0x3B); 	# 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)
  	my $AcY= $self->getI2CdataWord(0x3D); 	# 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
  	my $AcZ= $self->getI2CdataWord(0x3F);	# 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
	return($AcX,$AcY,$AcZ);
}
sub readAccelG {
	my $self = shift;
	my ($AcX,$AcY,$AcZ) = $self->readAccelRaw();
	my $AX = ($AcX & 0x8000) ? -((~$AcX & 0xffff) + 1) : $AcX;
	my $AY = ($AcY & 0x8000) ? -((~$AcY & 0xffff) + 1) : $AcY;
	my $AZ = ($AcZ & 0x8000) ? -((~$AcZ & 0xffff) + 1) : $AcZ;
	$AX = $AX / $self->{gDivisor};
	$AY = $AY / $self->{gDivisor};
	$AZ = $AZ / $self->{gDivisor};
	return($AX,$AY,$AZ);
}
sub readRawMPU6050 {
	my $self = shift;
	
  	my $AcX= $self->getI2CdataWord(0x3B); 	# 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)
  	my $AcY= $self->getI2CdataWord(0x3D); 	# 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
  	my $AcZ= $self->getI2CdataWord(0x3F);		# 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
	my ($Tmp,$TmpC,$TmpF) = $self->readTemp();
	my $GyX= $self->getI2CdataWord(0x43);		# 0x43 (GYRO_XOUT_H) & 0x44 (GYRO_XOUT_L)
  	my $GyY= $self->getI2CdataWord(0x45);		# 0x45 (GYRO_YOUT_H) & 0x46 (GYRO_YOUT_L)
  	my $GyZ= $self->getI2CdataWord(0x47);		# 0x47 (GYRO_ZOUT_H) & 0x48 (GYRO_ZOUT_L)
	return($AcX,$AcY,$AcZ,$Tmp,$GyX,$GyY,$GyZ,$TmpC,$TmpF);
}
sub wakeMPU {
	my $self = shift;
	my $maxG = shift;
	my $gBits = 0;
	
	if (!defined($maxG) || ($maxG == 2)) {
		$gBits = 0;
		$self->{gDivisor} = 16384;
		$self->{maxG} = 2;
	} elsif ($maxG == 4) {
		$gBits = 0x08;
		$self->{gDivisor} = 8192;
		$self->{maxG} = 4;
	} elsif ($maxG == 8) {
		$gBits = 0x10;
		$self->{maxG} = 8;
		$self->{gDivisor} = 4096;
	} elsif ($maxG == 16) {
		$gBits = 0x18;
		$self->{maxG} = 16;
		$self->{gDivisor} = 2048;
	} else {
		$gBits = 0x00;  # 2g
		$self->{maxG} = 2;
		$self->{gDivisor} = 8192;
	}
	my $mpu = $self->{MPU};
	$mpu->write_byte(0x01,0x6B);  # enable MPU and set clock to PLL w/ x-axis gyro
	# // Configure Gyro and Accelerometer
   # // Disable FSYNC and set accelerometer and gyro bandwidth to 44 and 42 Hz, respectively; 
   # // DLPF_CFG = bits 2:0 = 010; this sets the sample rate at 1 kHz for both
	$mpu->write_byte(0x03,0x1A);  # configuration
	
	$mpu->write_byte($gBits,0x1C);  # set accelerometer to +/- 2g
}

sub attach {
	my $self = shift;
	my $addy = shift;
		
	$self->{ready} = 0;
	if ($self->{MPU} = RPi::I2C->new($addy)) {
		$self->{ready} = $self->{MPU}->check_device($addy);
	}
	return ($self->{MPU});
}

sub new {
	my $class = shift;
	my $self = {};
	bless($self,$class);
	my $mpuaddy = shift;
	my $config = shift;
	
	$self->{directory} = "/home/pi/RPi";
	chdir($self->{directory});
	$self->{config} = $config;
	$self->{logconf} = $config->{logconf};
	$self->{myRole}= $config->{myRole};
	Log::Log4perl::init($self->{logconf});
	$self->{logger} = Log::Log4perl->get_logger();
	$self->{expectedAddy} = $config->{MPUAddy};
	$self->{expectedAddy} = 0x68 unless defined $self->{expectedAddy};
	$mpuaddy = $self->{expectedAddy} + 0;
	$self->{MPU} = $self->attach($mpuaddy);
	return ($self);
}

1;

