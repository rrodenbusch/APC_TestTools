#!/usr/bin/perl
use strict;
use warnings;

my %options;
use Getopt::Std;
getopts("pam",%options);
my @mykeys = keys(%options);
if ($#mykeys == -1 ) {
	$options{p} = 1;
	$options{a} = 1;
	$options{m} = 1;
}

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
	my $line = "$x";
	$line .= " $fields[0] $fields[1]" if (defined($options{p}));
	$line .= " $fields[2] $fields[3]" if (defined($options{a}));
	$line .= " $fields[4] $fields[5]" if (defined($options{m}));
	print "$line\n"; 
}

1;