#!/usr/bin/perl
use strict;
use warnings;

my %options;
use Getopt::Std;
getopts("xyzXYZgG",\%options);
my @mykeys = keys(%options);
if ($#mykeys == -1 ) {
	$options{X} = 1;
	$options{Y} = 1;
	$options{Z} = 1;
	$options{G} = 1;
} else {
	foreach my $curKey (@mykeys) {
		$options{uc($curKey)} = 1;
	}
}
my $ip = 221;
$ip = $ARGV[0] if defined($ARGV[0]);
my $cmd = 'ssh pi@192.168.0.' . "$ip " . '"cd /home/pi/I2C/i2cdata/MPU;/home/pi/APC_TestTools/tailCSV"';
open(my $fh, "$cmd |");
my $cnt = 0;

my $old_fh = select(STDOUT);
$| = 1;
select($old_fh);
my $line = <$fh>;
$line =~ s/\R//g;
my @fields = split(',',$line);
my $startTime = $fields[0];
while ($line = <$fh>) {
#	print $line;
	$line =~ s/\R//g;
	my @fields = split(',',$line);
	my ($epoch,$msec,$AcX,$AcY,$AcZ,$tmp,$tmpC,$tmpF,$totG) = @fields;
	if ($#fields == 8) {
 		my $x = 1000*($epoch - $startTime) + int($msec/1000);
		my $line = "$x";
		$line .= " $AcX" if (defined($options{X}));
		$line .= " $AcY" if (defined($options{Y}));
		$line .= " $AcZ" if (defined($options{Z}));
		if (defined($options{G})) {
			my $totG = sqrt($AcX*$AcX+$AcY*$AcY+$AcZ*$AcZ);
			$line .= " $totG"
		}
                warn "Bad line\t$line\n" if ($tmp == 65535);
		print "$line\n" if ($tmp != 65535); 
	} else {
		warn "Bad line\t$line\n";
	}
}

1;
