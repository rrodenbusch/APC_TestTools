#!/usr/bin/perl
use strict;
use warnings;

my $workDir = "$ENV{HOME}/MBTA/Working";
my $srcdir = "$ENV{HOME}/bin6";
chdir $workDir;
my @dirs = grep -d, glob "201*";

my $startDate = $ARGV[0];
if (!defined($startDate)) {die "Usage:  RunDates.pl  YYYYMMMDD  [YYYYMMDD]\n";}
my $endDate = $ARGV[1];
$endDate = "99999999" unless defined($endDate);
my $tarFile = "Reports.$startDate.tar";
`rm $tarFile`;
foreach my $dirname (@dirs) {
	if ( ($startDate <= $dirname) && ($dirname <= $endDate) ) {
		my @files = glob("$workDir/$dirname/*PeopleCounts$dirname.csv");
		foreach my $fname (@files){
			`cp $fname .`;
			my @name = split('/',$fname);
			my $name = pop(@name);
			if (-e $tarFile) {
				`tar -rf $tarFile $name`;
			} else {
				`tar -cf $tarFile $name`; 	
			}
			` rm $fname`;
		}
	}
}
`gzip -fk $tarFile`;

1;