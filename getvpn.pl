#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;

sub readINI {
	my $self = shift;
	my %ini;
	my %devices;
	my @file;
	
	
	# Read the file into memory
	open(my $fh, "$ENV{HOME}/RPi/config.ini");
	while( my $line = <$fh>) {
		$line =~ s/\R//g;
		push(@file, $line);
	}
	close($fh);

	@file = grep m/^[^#]/, @file;  # skip comments
	for (@file) {
		chomp;
		my ($key, $val) = split /=/;
		$key =~ s/\R//g;
		$val =~ s/\R//g;
		if ($key eq 'I2C_Device') {
			my($I2addy,$I2device,$I2name,$I2optional) = split(',',$val);
			$I2addy = hex($I2addy);
			$devices{$I2addy}->{name} = $I2name;
			$devices{$I2addy}->{optional} = $I2optional;
			$devices{$I2addy}->{type} = $I2device;
		} else {
			$self->{$key}=$val;
			$ini{$key}=$val;
		}
	}
	$self->{ini}= \%ini;
	$self->{I2Cconfig} = \%devices;
	
	return($self->{ini});
}	# end readINI


my $config = readINI();
my $subnet = '192.168.0';
$subnet = $config->{subnet} if (defined($config->{subnet}));
print "$config->{myRole}";
my $ifconfig = `/sbin/ifconfig`;
my @lines = split(/\R/,$ifconfig);
my ($dev,$ip,$mac) = ('','','');
foreach my $myline (@lines) {
	my @words = split(" ",$myline);
	if (defined($words[0]) ) {
		if (substr($words[0],-1) eq ':') {
			print ",$dev $ip $mac" if ($dev ne '') && ($dev ne 'lo');
			$dev = $words[0];
			$dev =~ s/://g;
		} else {
			if ($words[0] eq 'inet') {
				$ip = $words[1];
			} elsif ($words[0] eq 'inet6') {
				$mac = uc($words[1]);
			} elsif ($words[0] eq 'ether') {
				$mac = uc($words[1]);
			} 
		}
	}
}
print ",$ip,$mac,$dev\n" if ($dev ne '') && ($dev ne 'lo:');

1;