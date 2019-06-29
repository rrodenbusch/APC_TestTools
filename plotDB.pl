#!/usr/bin/perl
use strict;
use warnings;

my $cmd = 'ssh pi@192.168.0.221 "cd /home/pi/I2C/i2cdata/dB;/home/pi/APC_TestTools/tailCSV.sh"';
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
	@fields = split(',',$line);
	my $epoch = shift(@fields);
	my $msec = shift(@fields);
 	my $x = 1000*($epoch - $startTime) + int($msec/1000);
	my $line = "$x ".join(' ',@fields);
	print "$line\n"; 
}

1;