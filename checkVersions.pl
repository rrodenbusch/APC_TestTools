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
$device = $options{d} if defined($options{c});
$version = $options{v} if defined($options{c});
print "   Checking version $version on coach $coach device $device\n";

chdir ($VersionDir) or die "Unable to access $VersionDir\n$!\n";
my @files = glob("$coach.$device.$version.*.log");
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
	print "$coach \t";
	foreach my $curDevice (sort(keys(%{$Versions{$curCoach}}))) {
		print "$curDevice\t" ;
			foreach my $curMajor (sort(keys(%{$Versions{$curCoach}->{$curDevice}}))) {
				print "$curMajor\t" ;
				foreach my $curMinor (sort(keys(%{$Versions{$curCoach}->{$curDevice}->{$curMajor}}))) {
					print "$curMajor\t" . $Versions{$curCoach}->{$curDevice}->{$curMajor} . "\n";
			}
		}
	}
}

1;
