#!/usr/bin/perl
use lib "$ENV{HOME}/bin6";

use strict;
use warnings;
use ConsistStatus;
use POSIX qw(strftime);
use Getopt::Std;

my $EVENTGAPTIME = 300;
my $GPSGAPTIME = 300;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("hc:d:e:g:", \%options);
if (defined $options{h})	{
	print "Usage: CheckOffline -c coach [ALL] -d YYYYMMDD [today] -e Event Timeout [300] -g GPS Timeout [300]\n";
	exit;
}

sub readGPS {
	#
	#	FILE:	< $coach.GPS.csv
	#
	my ($fleetDefn,$coach,$outfh) = @_;
	my (%lastTime);
	
	my $fname = "$coach.GPS.csv";
	my ($epoch,$gpsID,$date1,$date2,$date3,$valid,$lat,$lon,$line,$datestr,$speed,$coachID);
	if (open(my $fh, $fname ) ) {
		while (my $line = <$fh> ) {
			$line =~ s/\R//g;
			($epoch,$gpsID,$datestr,$valid,$lat,$lon,$speed,$coachID) = split(',',$line);
			my $delta = $epoch - $lastTime{epoch} if (defined($lastTime{epoch}));
			if (defined($lastTime{epoch}) && ($delta > $GPSGAPTIME)) {
				my ($lastLat,$lastLon) = ($lastTime{lat}, $lastTime{lon});
				my ($name1,$atStation1,$terminus1) = $fleetDefn->findStation($lastLat,$lastLon);
				my ($name2,$atStation2,$terminus2) = $fleetDefn->findStation($lat,$lon);
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{epoch} + 3600));
				my $timeStr2 = strftime("%H:%M:%S",localtime($epoch + 3600));
				$delta = int(100*$delta/60) / 100; 
				my $outline = "$lastTime{epoch},$coach,0,GPS,$timeStr1,$timeStr2,$delta,$name1,$name2,$gpsID,$epoch\n";
				print $outfh $outline;
				print $outline;		
			} elsif (!defined($lastTime{epoch})) {
				my ($name2,$atStation2,$terminus2) = $fleetDefn->findStation($lat,$lon);
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($epoch + 3600));
				my $outline = "$epoch,$coach,0,GPS,$timeStr1,FIRSTREC,FIRSTREC,$name2,FIRSTREC,$gpsID,$epoch\n";
				print $outfh $outline;
				print $outline;		
			}
			($lastTime{lat}, $lastTime{lon},$lastTime{epoch}) = ($lat,$lon, $epoch);	
		}
		# last record
		my ($name2,$atStation2,$terminus2) = $fleetDefn->findStation($lat,$lon);
		my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{epoch} + 3600));
		my $timeStr2 = strftime("%H:%M:%S",localtime($epoch + 3600));
		my $outline = "$lastTime{epoch},$coach,0,GPS,$timeStr1,LASTREC,LASTREC,$name2,LASTREC,$gpsID,$epoch\n";
		print $outfh $outline;
		print $outline;		
		close($fh);	
	} else {
		my $outline = "0,$coach,GPS,NODATA,$!\n";
		print $outfh $outline;
		print $outline;
	}
}	# readGPS

sub readEvents {
	#
	#	FILE:	< $coach.AllPCN.csv
	#	FILE:	< $coach.AllNVF.csv
	#
	my ($fleetDefn,$coach,$outfh) = @_;
	my (%lastTime);
	
	my $fname;
	$fname = "$coach.AllNVF.csv" if (-e "$coach.AllNVF.csv");
	$fname = "$coach.AllPCN.csv" if (-e "$coach.AllPCN.csv");
	my ($timestr,$epoch,$type,$threshold,$mac,$host,$coachID,$end,$line,$inCnt,$outCnt);
	if (open my $fh, $fname) {
		while (my $line = <$fh> ) {
			$line =~ s/\R//g;
			my @fields = split(',',$line);
			($timestr,$epoch,$type,$threshold,$mac,$host,$inCnt,$outCnt,$coachID,$end) = split(',',$line);
			my $delta = $epoch - $lastTime{$end}->{epoch} if (defined($lastTime{$end}->{epoch}));
			if (defined($delta) && ($delta > $EVENTGAPTIME) ) {
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{$end}->{epoch} + 3600));
				my $timeStr2 = strftime("%H:%M:%S",localtime($epoch + 3600));
				$delta = int(100*$delta/60);
				my $outline = "$epoch,$coach,$end,EVENTS,$timeStr1,$timeStr2,$delta,,,$coachID,$epoch\n";
				print $outfh $outline;
				print $outline;
			} elsif (!defined($delta)) {
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($epoch + 3600));
				my $outline = "$epoch,$coach,$end,EVENTS,$timeStr1,FIRSTREC,FIRSTREC,,,$coachID,$epoch\n";
				print $outfh $outline;
				print $outline;
			}
			$lastTime{$end}->{epoch} = $epoch;
		}
		foreach my $curEnd (keys(%lastTime)) {
			my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{$curEnd}->{epoch} + 3600));
			my $outline = "$lastTime{$curEnd}->{epoch},$coach,$curEnd,EVENTS,$timeStr1,LASTREC,LASTREC,,,$coachID,LASTREC\n";
			print $outfh $outline;
			print $outline;
		}
		close($fh);
	} else {
		my $outline = "0,$coach,3,EVENTS,NODATA,$!\n";
		print $outfh $outline;
		print $outline;
	}
}	# readEvents

my ($startepoch,$stopepoch,$from,$end,$dirname) = ConsistStatus::setupTimeWindow();
my $fleetDefn = ConsistStatus->new("$ENV{HOME}/bin6");
my $coachNames = $fleetDefn->coachNames();
$dirname = $options{d} if defined($options{d});
$GPSGAPTIME = $options{g} if defined($options{g});
$EVENTGAPTIME = $options{e} if defined($options{e});
if (defined($options{c})) {
	@{$coachNames} = ($options{c});
}
chdir("$ENV{HOME}/MBTA/Working/$dirname") or die "Unable to change to $dirname\n$!\n";

open(my $outfh, ">OfflineStatus.csv" ) or die "Unable to open OfflineStatus.csv\n\t$!";
foreach my $coach (@{$coachNames}) {
	readGPS($fleetDefn,$coach,$outfh);
	readEvents($fleetDefn,$coach,$outfh);
}
close($outfh);
`/usr/bin/sort -k1 -t"," OfflineStatus.csv >SortedOfflineStatus.csv`;

1;