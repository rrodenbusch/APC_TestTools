package Ard_APC;
use lib "$ENV{HOME}/RPi";
##########################################
#
#  Basic Socket configuration for NVF
#
##########################################
use strict;
use warnings;
use RPi::I2C;
use RPiConfig;
use RemoteLog;

my %ArdCmds = (
	'ExpectedVersion' => 8,
	'Version' => 0x01,
	'Mode' => 0x02,
	'Doors' => 0x03,
	'Sound1' => 0x04,
	'Sound2' => 0x05,
	'Temp' => 0x06
);

sub readI2Cbyte {
	my ($self,$timeout) = @_;
	my ($data,$retData) = (-1,-1);
	my $cnt = 0;
	my $delaytics = 10;
	my $loopcnt = $timeout / $delaytics;
	my $device = $self->{ard};

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
	my $device = $self->{ard};

	do {  # wait for return a max of one second
		@bytes = $device->read_block(2,$cmd);
		Time::HiRes::usleep($delaytics) if (!defined($bytes[0])); # milliseconds
	} while ( (!defined($bytes[0])) && ($cnt++ < $loopcnt) );
	return (@bytes);
}
sub getI2CdataByte {
	my ($self,$cmd,$timeout) = @_;
	$timeout = 1000 if !defined($timeout);  # default time is 1 second
	my $device = $self->{ard};
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
sub getVersion {
	my $self = shift;
	my ($version,$cnt) = $self->getI2CdataByte($ArdCmds{'Version'});
	my $expectedVersion = $self->{expectedVersion};
	if ($version ne $expectedVersion) {
		if (my $logger = $self->{remoteLogger}) {
			$logger->sendMessage("ArdAPC: Version Mismatch $version vs".
								" $expectedVersion");
		}
	}
	return ($version);
}
sub getMode {
	my $self = shift;
	my ($mode,$cnt) = $self->getI2CdataByte($ArdCmds{'Mode'});
	$mode = chr($mode);
	return ($mode);
}
sub getDoors {
	my $self = shift;
	my ($doors,$cnt) = $self->getI2CdataByte($ArdCmds{'Doors'});
	return ($doors,$cnt);
}
sub getSound1 {
	my $self = shift;
	my ($snd1,$cnt) = $self->getI2CdataByte($ArdCmds{'Sound1'});
	my $db1 = $snd1;
	$db1 = ($snd1&0x7F) - 128 if ($snd1 & 0x80); 
	return ($db1);
}
sub getSound2 {
	my $self = shift;
	my ($snd2,$cnt) = $self->getI2CdataByte($ArdCmds{'Sound2'});
	my $db2 = $snd2;
	$db2 = ($snd2&0x7F) - 128 if ($snd2 & 0x80); 
	return ($db2);
}
sub getTemp {
	my $self = shift;
	my ($temp,$cnt) = $self->getI2CdataWord($ArdCmds{'Temp'});
	$temp = ($temp & 0x7FFF) - 32768 if ($temp & 0x8000);
	return ($temp);
}
sub getData {
	my $self = shift;
	my $response = '';
	my $device = $self->{ard};
	my $addy = $self->{expectedAddy};
	$addy = 8 unless defined($addy);
	$addy += 0;
	$self->{ard} = RPi::I2C->new($addy) if (!$device );
	if ($device) {
		my @bytes1 = $device->read_block(254, 0);
		my @bytes2 = $device->read_block(254, 0);
		foreach my $char (@bytes1) {
			$response .= chr($char) unless $char == 255;
		}
		$response .= ":";
		foreach my $char (@bytes2) {
			$response .= chr($char) unless $char == 255;
		}
	}
	return $response;
}
sub attach {
	my $self = shift;
	my $addy = shift;

	$self->{ready} = 0;
	if ($self->{ard} = RPi::I2C->new($addy)) {
		$self->{ready} = $self->{ard}->check_device($addy);		
	}
	return ($self->{ard});
}

sub new {
	my $class = shift;
	my $self = {};
	bless($self,$class);
	my $addy = shift;
	my $config = shift;
	
	$self->{directory} = "/home/pi/RPi";
	chdir($self->{directory});
#	if (!defined($config)) {#
#		$config = new RPiConfig();
#		$config->mapNetwork();	
#	}
#	$self->{config} = $config;
#	$self->{logconf} = $config->{logconf};
#	$self->{myRole}= $config->{myRole};
#	Log::Log4perl::init($self->{logconf});
#	$self->{logger} = Log::Log4perl->get_logger();       
#	$self->{expectedAddy} = $config->{ArdAddy};
	$self->{expectedAddy} = 0x08;
	$self->{expectedVersion} = $config->{ArdVersion};
	
#	$self->{signals} = \%sig;
	$addy = $self->{expectedAddy} + 0;
	$self->{ard} = $self->attach($addy);
	return ($self);
}

1;

