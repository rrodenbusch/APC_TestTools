#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
#use Net::Ping;

my %options=();
getopts("hc:d:v:",\%options);
my $FBDdir = "/media/data/FBD";
my $VersionDir = "$FBDdir/PiUpdates";
my %Versions;

warn "Usage:  checkVersions.pl  -c coach -d device -v version\n" if (defined$options{h});
my ($coach,$device,$version) = ("*","*","*");

$coach = $options{c} if defined($options{c});
$device = $options{d} if defined($options{d});
$version = $options{v} if defined($options{v});
print "   Checking version $version on coach $coach device $device\n";

chdir ($VersionDir) or die "Unable to access $VersionDir\n$!\n";
my $pattern = "$coach.$device.$version.*.log";
my @files = glob("$pattern");
foreach my $fname (@files) {
	my ($coachStr,$deviceStr,$major,$minor,$dateStr,$ext) = split('\.',$fname);
	if ( !defined($Versions{$coachStr}) || (!defined($Versions{$coachStr}->{$deviceStr})) ||
		  !defined($Versions{$coachStr}->{$deviceStr}->{$major}) || 
		  !defined($Versions{$coachStr}->{$deviceStr}->{$major}->{$minor}) ||
		  	       ($Versions{$coachStr}->{$deviceStr}->{$major}->{$minor} < $dateStr) ) {	
		$Versions{$coachStr}->{$deviceStr}->{$major}->{$minor} = $dateStr;
	}
}

foreach my $curCoach (sort(keys(%Versions))) {
	if ( ($curCoach ne '') && ($curCoach ne 'Lab') ) {
		my $coachStr = $curCoach;
		$coachStr =~ s/ //g;
		$coachStr = sprintf( "%-9s",$coachStr);
		foreach my $curDevice (sort(keys(%{$Versions{$curCoach}}))) {
			my $deviceStr = $curDevice;
			$curDevice =~ s/ //g;
			$curDevice =~ s/MAC//g;
			$curDevice = sprintf('%-9s',$curDevice);
			foreach my $curMajor (sort(keys(%{$Versions{$curCoach}->{$deviceStr}}))) {
				foreach my $curMinor (sort(keys(%{$Versions{$curCoach}->{$deviceStr}->{$curMajor}}))) {
					print "$curCoach\t$curDevice\t$curMajor.$curMinor\t" . $Versions{$curCoach}->{$deviceStr}->{$curMajor}->{$curMinor} . "\n";
				}
			}
		}		
	}
}

1;
