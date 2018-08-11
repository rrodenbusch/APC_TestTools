use lib "$ENV{HOME}/bin";
#
#	Reads all the GPS and Events files to find gaps 
#
#

use strict;
use warnings;
use ConsistStatus;
use POSIX qw(strftime);
my $GAPTIME = 300;

sub readGPS {
	my ($SetID,$outfh) = @_;
	my (%lastTime);
	my $stationData = ConsistStatus::loadStations();
	my %gpsToCoach = ConsistStatus::GetGPStoCoach();
	my $maxEpoch = 0;
	
	open(my $fh, "$SetID.SortedGPS.csv") or die "Unable to open $SetID.SortedGPS.csv\n\t$!\n";
	while (my $line = <$fh> ) {
		$line =~ s/\R//g;
		my ($epoch,$coachID,$date1,$date2,$date3,$valid,$lat,$lon) = split(',',$line);
		$coachID =~ s/ //g;
		if (defined($lastTime{$coachID} )) {
			my $delta = $epoch - $lastTime{$coachID}->{epoch};
			if ($delta > $GAPTIME) {
				my ($lastLat,$lastLon) = ($lastTime{$coachID}->{lat}, $lastTime{$coachID}->{lon});
				my ($name1,$atStation1,$terminus1) = ConsistStatus::findStation($stationData,$lastLat,$lastLon);
				my ($name2,$atStation2,$terminus2) = ConsistStatus::findStation($stationData,$lat,$lon);
				my $coach = $gpsToCoach{$coachID};
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{$coachID}->{epoch} + 3600));
				my $timeStr2 = strftime("%H:%M:%S",localtime($epoch + 3600));
				$delta = int(100*$delta/60) / 100; 
				my $outline = "$timeStr1,$timeStr2,$coach,$delta,$name1,$name2,$SetID,$epoch\n";
				print $outfh $outline;
				print $outline;		
				$lastTime{$coachID}->{epoch} = $epoch;
			}
			$maxEpoch = $epoch; 	
		}
		($lastTime{$coachID}->{lat}, $lastTime{$coachID}->{lon},$lastTime{$coachID}->{epoch}) = 
																					($lat,$lon, $epoch);																			
	
	}
		
	foreach my $coachID (sort(keys(%lastTime))) {
		if ($coachID ne 'coach') {
			my $epoch = $lastTime{$coachID}->{epoch};
			my $delta = $maxEpoch - $epoch;
			if ($delta > $GAPTIME) {
				my ($lastLat,$lastLon) = ($lastTime{$coachID}->{lat}, $lastTime{$coachID}->{lon});
				my ($name1,$atStation1,$terminus1) = ConsistStatus::findStation($stationData,$lastLat,$lastLon);
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{$coachID}->{epoch} + 3600));
				my $timeStr2 = strftime("%H:%M:%S",localtime($maxEpoch + 3600));
				$delta = int(100*$delta/60);
				my $coach = $gpsToCoach{$coachID};
				my $outline = "$timeStr1,$timeStr2,$coach,$delta,,,$SetID,$epoch\n";
				print $outfh $outline;
				print $outline;
			}
		}
	}
}	# readGPS

sub readEvents {
	my ($SetID,$outfh) = @_;
	my (%lastTime);
	my $stationData = ConsistStatus::loadStations();
	my %gpsToCoach = ConsistStatus::GetGPStoCoach();
	
#	my $line =  $SetID.AllEventCounts.csv $SetID.AllEventCountsSorted.csv
	system("../../../bin/SortShell.sh"); # Sort the events files
	open(my $fh, "$SetID.AllEventCountsSorted.csv") or die "Unable to open $SetID.AllEventCountsSorted.csv\n\t$!\n";
	<$fh>; # header
	my $maxEpoch = 0;
	while (my $line = <$fh> ) {
		$line =~ s/\R//g;
		my @fields = split(',',$line);
		my ($timestr,$coach,$end,$inCnt,$outCnt,$delta,$epoch,$InCntr,$OutCntr,$mac,$host) = split(',',$line);
		if (defined($lastTime{$coach} )) {
			my $delta = $epoch - $lastTime{$coach}->{epoch};
			if ($delta > $GAPTIME) {
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{$coach}->{epoch} + 3600));
				my $timeStr2 = strftime("%H:%M:%S",localtime($epoch + 3600));
				$delta = int(100*$delta/60);
				my $outline = "$timeStr1,$timeStr2,$coach,$delta,,,$SetID,$epoch\n";
				print $outfh $outline;
				print $outline;
			}
		}
		if ($coach ne 'coach') {
			$lastTime{$coach}->{epoch} = $epoch;
			$maxEpoch = $epoch; 	
		}
	}
	
	foreach my $coach (sort(keys(%lastTime))) {
		if ($coach ne 'coach') {
			my $epoch = $lastTime{$coach}->{epoch};
			my $delta = $maxEpoch - $epoch;
			if ($delta > $GAPTIME) {
				my $timeStr1 = strftime("%Y%m%d,%H:%M:%S",localtime($lastTime{$coach}->{epoch} + 3600));
				my $timeStr2 = strftime("%H:%M:%S",localtime($maxEpoch + 3600));
				$delta = int(100*$delta/60);
				my $outline = "$timeStr1,$timeStr2,$coach,$delta,,,$SetID,$epoch\n";
				print $outfh $outline;
				print $outline;
			}
		}
	}
}	# readEvents


my ($startepoch,$stopepoch,$from,$end,$dirname) = ConsistStatus::setupTimeWindow();
$dirname = $ARGV[0] if defined($ARGV[0]);
chdir("$ENV{HOME}/MBTA/Working/$dirname");
my @files = glob('*.SortedGPS.csv');
my @Sets = ();
foreach my $fname (@files) {
	my @flds = split("\\.",$fname);
	push(@Sets, $flds[0]);
}

open(my $outfh, ">CoachStatus.csv" ) or die "Unable to open CoachStatus.csv\n\t$!";
print $outfh "Date,TimeOff,TimeOn,Coach,Delta (min),Offline,Online,SetID,Epoch\n";
print "Date,TimeOff,TimeOn,Coach,Delta (min),Offline,Online,SetID,Epoch\n";
foreach my $setID (@Sets) {
	readGPS($setID,$outfh);
	readEvents($setID,$outfh);
}
close($outfh);

1;