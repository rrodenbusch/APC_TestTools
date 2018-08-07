#!/usr/bin/perl
use lib "$ENV{HOME}/bin6";
use strict;
use warnings;
use ConsistStatus;
use File::Copy;
use POSIX qw(strftime);
use JSON;
#use Date::Parse;

##########################################################################
#
#	Arguments:
#		YYYY-MM-DD [optional]  - date to run status
#
#
#	Inputs
#		AllEvents.csv : has the events from the PCNs. 
#		SortedGPS.csv : has the GPS cooredinates
#		PeopleCountsDetails.csv: Last Stop; Last Station
#
#   Outputs
#		CurrentStatus.csv
#
#	4/23/18		Updated for the new GPS file format
#	5/8/18		Updated for the flats (NUC2)
#		
##########################################################################	
my $DataOfflineWindow = 300;
my $GPSOfflineWindow = 300; #run could be up to 15 minutes old; plus some lag time
my $EASTERN_OFFSET = 1;

sub queryLastGPS {
	#
	#  Open a session and select all the most recent GPS records
	#
	#
	my ($curConsist) = @_;
	my $KNOTS2MPH = 1.15;
	my %gpsData;

	print "Requesting GPS positions\n";
	my $reqURL = '"https://mbta-gw4.mthinxiot.com/api/sql/query" -d "select * from KNOWNGPSFIX"';
   my $content = `curl -m 1000 --connect-timeout 800 -sS -X POST $reqURL 2>&1`;
	if (substr($content,0,2) eq '[[') {
		$content =~ s/],\[/\n/g;
		$content =~ s/]//g;
		$content =~ s/\[//g;
		my @lines = split("\n",$content);
		my $count = @lines;
		if( $count > 1 ) {
			print "Saving $count GPS Positions\n";
			while (my $line = shift(@lines)) {
				my @fields = split(',',$line);
				my ($startime,$id,$ibr,$coachNum,$lat,$lon,$speed) = ($fields[0],$fields[1],$fields[2],$fields[3],$fields[5],$fields[6],$fields[7]);
				my $coach = $curConsist->gps2coach($id);
				$coach = $ibr unless defined($coach);
				my $epoch = $startime / 1000;  # back to seconds
				$speed *= $KNOTS2MPH;
				my $datestr = strftime( "%Y%m%d %H:%M:%SZ", gmtime($epoch) );
				my $output = "$epoch,$id,$datestr,true,$lat,$lon,$speed";
				$gpsData{$coach}->{epoch} = $epoch;
				$gpsData{$coach}->{id} = $id;
				$gpsData{$coach}->{dateStr} = $datestr;
				$gpsData{$coach}->{lat} = $lat;
				$gpsData{$coach}->{lon} = $lon;
				$gpsData{$coach}->{speed} = $speed;
			}	
		}
	} else {
		print "GPS Error $content\n";
	}
	return(\%gpsData);
}	# queryLastGPS

sub queryEventRecords {
	#
	# 	Query one of the data sets and write out the data
	#
	my ($curConsist,$ua,$reqURL,$type,$EventTimes) = @_;
	
	my $req = new HTTP::Request GET => $reqURL;
	my $response2 = $ua->request($req);
	if ($response2->is_success ) {
		my $content = $response2->decoded_content;
		my $hashref = decode_json($content);
		my $arrayref = ${$hashref}[0];
		my $pointref = ${$arrayref}{'points'};
		my $header = ${$arrayref}{'columns'};
		my $numCols = scalar @{$header};
		my($timeIdx,$hostIdx,$macIdx) = (0,0,0);
		for (my $i=0;$i<$numCols;$i++) {
			$timeIdx = $i if ($header->[$i] eq 'time');
			$hostIdx = $i if ($header->[$i] eq 'host');
			$macIdx =  $i if ($header->[$i] eq 'mac');	
		}
		my $headerline = join(',',@{$header});
		my $fldcnt = scalar @{$header};
		while (my $curpoint = shift (@{$pointref})) {
			my ($time,$host,$mac) = (${$curpoint}[$timeIdx],${$curpoint}[$hostIdx],${$curpoint}[$macIdx]);
			$time /= 1000;
			my ($coach,$device,$end);
			($coach,$device,$end) = $curConsist->decodePCN($mac,$host) if ($type eq 'PCN');
			($coach,$device,$end) = $curConsist->decodeNVF($mac,$host) if ($type eq 'NVF');
			$EventTimes->{$coach}->{$end} = $time if ( !defined($EventTimes->{$coach}) || 
																!defined($EventTimes->{$coach}->{$end}) ||
																($time > $EventTimes->{$coach}->{$end}) );
		}
	} else {
		my $resp_msg = $response2->status_line();
		print "Error selecting events [$reqURL]: $resp_msg\n";
	}
	return($EventTimes);
}	# queryEventRecords

sub queryLastData {
	my ($curConsist,$ua) = @_;
	my %EventTimes;
	
	my $end = time();
	my $start = $end - 900;	# get last 15 minutes
	my $NVFurl =  'https://influxserver.mthinx.com/db/sensor-events/series?p=pass79&q='.
						'select+time,+host,+mac+from+%22universe.ember-count-both%22+where+'.
						"time+%3E+$start"."s+and+time+%3C+$end"."s".
						'+group+by+time(1s)+order+asc&u=sensor-events';
	my $PCNurl =  'https://influxserver.mthinx.com/db/sensor-events/series?p=pass79&q='.
						'select+time,+host,+mac+from+%22universe.sensor%22+where+'.
						"time+%3E+$start"."s+and+time+%3C+$end"."s".
						'+group+by+time(1s)+order+asc&u=sensor-events';

	queryEventRecords($curConsist, $ua, $PCNurl, 'PCN', \%EventTimes);
	queryEventRecords($curConsist, $ua, $NVFurl, 'NVF', \%EventTimes);

	return(\%EventTimes);
}	# queryLastData

sub findLastPositions {
	#
	#	FILE:	<	$coach.Schedule.csv
	#
	my ($curConsist,$ua,$coachNames) = @_;
	my %lastPositions;

	foreach my $coach (@$coachNames) {
		my @data;
		@data = `cat $coach.Schedule.csv` if (-e "$coach.Schedule.csv");
		if (scalar @data > 0) {
			shift(@data);  	# take off the header
			do {
				my $lastStop = pop(@data);
				$lastStop =~ s/\R//g;
				my @flds = split(',',$lastStop);
				my $coach = $flds[0];
				my $station = $flds[2];
				my ($arr,$dep) = ($flds[11],$flds[12]);
				my $atStation = $flds[13];
				my $epoch = $arr;
				if ($station ne 'InMotion') {		
					$lastPositions{$coach}->{stop} = $station;
					$lastPositions{$coach}->{stopTime} = $arr;
					if ($atStation == 1) {
						$lastPositions{$coach}->{station} = $station;
						$lastPositions{$coach}->{stationTime} = $arr;				
					}
				}
			} while ( (scalar @data > 0) && (!defined($lastPositions{$coach}->{station})) );
		} else {
			$lastPositions{$coach}->{station} = '';
			$lastPositions{$coach}->{stop} = '';
			$lastPositions{$coach}->{stationtime} = '';
			$lastPositions{$coach}->{stoptime} = '';
		}
	}
	return(\%lastPositions);
}	# 	findLastPositions

sub readLastOnline {
	#
	#		FILE:	<LastOnline.csv
	#
	my $prevdirname = shift;
	my $lastOnline;

	if (open(my $fh, "<../$prevdirname/LastOnline.csv") ) {
		# Read in end of day yesterday first
		<$fh>;
		while (my $line = <$fh>) {
			$line =~ s/\R//g;
			my ($coach,$gpsepoch,$lat,$lon,$data1,$data2) = split(',',$line);
			$lastOnline->{$coach}->{gps}->{lat} = $lat;
			$lastOnline->{$coach}->{gps}->{lon} = $lat;
			$lastOnline->{$coach}->{gps}->{epoch} = $gpsepoch;
			$lastOnline->{$coach}->{1} = $data1;
			$lastOnline->{$coach}->{2} = $data2;
		}
		close($fh);
	} else {
		print "Unable to open LastOnline.csv\t$!\n";
	}

	if (open(my $fh, "<LastOnline.csv") ) {
		# Lay on top any data from today
		<$fh>;
		while (my $line = <$fh>) {
			$line =~ s/\R//g;
			my ($coach,$gpsepoch,$lat,$lon,$data1,$data2) = split(',',$line);
			if (defined($gpsepoch) && ($gpsepoch ne '') && ($gpsepoch > 0)) {		
				$lastOnline->{$coach}->{gps}->{lat} = $lat;
				$lastOnline->{$coach}->{gps}->{lon} = $lat;
				$lastOnline->{$coach}->{gps}->{epoch} = $gpsepoch;
			}
			$lastOnline->{$coach}->{1} = $data1 if ((defined($data1)) && ($data1 ne '') && ($data1 > 0));
			$lastOnline->{$coach}->{2} = $data2 if ((defined($data2)) && ($data2 ne '') && ($data2 > 0));
		}
		close($fh);
	} else {
		print "Unable to open LastOnline.csv\t$!\n";
	}

	return($lastOnline);
}	#	readLastOnline

sub writeLastOnline {
	#
	#		FILE:	>	LastOnline.csv
	#
	my $lastOnline = shift;
	
	if (open(my $fh, ">LastOnline.csv") ) {
		print $fh "Coach,GPStime,lat,lon,Data1Time,Data2Time\n";
		foreach my $coach (sort(keys(%$lastOnline))) {
			my ($gpsepoch,$lat,$lon,$data1,$data2) = ('','','','','');
			if (defined($lastOnline->{$coach}->{gps})) {
				$gpsepoch =	$lastOnline->{$coach}->{gps}->{epoch};
				$lat = $lastOnline->{$coach}->{gps}->{lat};
				$lon = $lastOnline->{$coach}->{gps}->{lon};
			}
			$data1 =  $lastOnline->{$coach}->{1} if (defined($lastOnline->{$coach}->{1}));
			$data2 =  $lastOnline->{$coach}->{2} if (defined($lastOnline->{$coach}->{2}));
			my $line = "$coach,$gpsepoch,$lat,$lon,$data1,$data2";
			print $fh "$line\n";
		}
		close($fh);
	} else {
		print "Unable to open LastOnline.csv\t$!\n";
	}
}	#	writeLastOnline

sub readLastData {
	 #
	 #	FILE:	<	LastEvents.csv
	 #
	 my $LastData;
	if (open (my $fh, "<LastEvents.csv") ) {
		while (	my $line = <$fh> ) {
	 		$line =~ s/\R//g;
	 		my ($coach,$end,$epoch) = split(',',$line);
	 		$LastData->{$coach}->{$end} = $epoch;
		}
	}
	 return($LastData);
}	# 	readLastData

sub readLastGPS {
	 #
	 #	FILE:	<	LastGPS.csv
	 #
	 my $LastGPS;
	if (open (my $fh, "<LastGPS.csv") ) {
		while (	my $line = <$fh> ) {
	 		$line =~ s/\R//g;
	 		my ($coach,$epoch,$lat,$lon) = split(',',$line);
	 		$LastGPS->{$coach}->{epoch} = $epoch;
	 		$LastGPS->{$coach}->{lat} = $lat;
	 		$LastGPS->{$coach}->{lon} = $lon;
		}
	}
	 return($LastGPS);
}	# 	readLastGPS

#
#   MAIN
#
# Get the directory and current date and previous date for the GPS extraction
#   The schedule determines the window for the entire report
#

my ($startepoch,$stopepoch,$from,$end,$dirname,$predirname) = ConsistStatus::setupTimeWindow();
my ($srcdir, $workdir,$outdir) = ConsistStatus::setupWorkingDirectory($dirname);
chdir($workdir) or die "Unable to change to $workdir\t$!";

my $curConsist = ConsistStatus->new($srcdir);
my $ua = $curConsist->NVFbrowser();
my $coachNames = $curConsist->coachNames();
my $lastOnline = readLastOnline($predirname);

my ($gpsLastStatus,$dataLastStatus,$lastPositions,$epoch);
if ($ARGV[0]) {
	# Read end of day files
	$gpsLastStatus = readLastGPS(); # read from $coach.SortedGPS.csv
	$dataLastStatus = readLastData();	# read from $coach.SortedEvents.csv
	$epoch = $stopepoch - 15*60; # back off 15 minutes for previous runtime;
} else {
	# Get current status
	$gpsLastStatus = queryLastGPS($curConsist);
	$dataLastStatus = queryLastData($curConsist,$ua);
	$lastPositions = findLastPositions($curConsist,$ua,$coachNames);
	$epoch = time();
}
$lastPositions = findLastPositions($curConsist,$ua,$coachNames);	# read from $coach.Schedule.csv

my $timeline = strftime("%Y%m%d,%H:%M",localtime($epoch+$EASTERN_OFFSET*3600));
my $header = "Coach,Date,Time,LastGPSTime,GPSStatus,Lat,Lon,StopTime,LastStop,StationTime,LastStation,".
				"Data1Time,Data1Status,Data2Time,Data2Status";
my $curepoch = $epoch;
if (open(my $outfh, ">CurrentStatus.csv") ) {
	print $outfh "$header\n";
	foreach my $coach (sort (@$coachNames) ) {
		if ( (index(uc($coach),'ALT') == -1) && (uc($coach) ne 'LAB') ) {
			my $stopepoch = $lastPositions->{$coach}->{stopTime};
			my $stopname = $lastPositions->{$coach}->{stop};
			my $stationepoch = $lastPositions->{$coach}->{stationTime};
			my $stationname = $lastPositions->{$coach}->{station};
			my $lat = '';
			$lat = sprintf("%0.6f",$gpsLastStatus->{$coach}->{lat}) if (defined($gpsLastStatus->{$coach}->{lat}));
			my $lon = '';
			$lon = sprintf("%0.6f",$gpsLastStatus->{$coach}->{lon}) if (defined($gpsLastStatus->{$coach}->{lon}));
			my $gpsepoch = $gpsLastStatus->{$coach}->{epoch};
			
			my $gpsStatus = 'Offline';
			my $gpstimeline = '';
			$gpstimeline = strftime("%Y%m%d %H:%M",localtime($gpsepoch+$EASTERN_OFFSET*3600)) if (defined($gpsepoch));
			if ( defined($gpsepoch) ) {
				$gpsStatus = 'Online' if ($curepoch - $gpsepoch < $GPSOfflineWindow);  # Less than 5 minutes old
				$lastOnline->{$coach}->{gps}->{epoch} = $gpsepoch;
				$lastOnline->{$coach}->{gps}->{lat} = $lat;
				$lastOnline->{$coach}->{gps}->{lon} = $lon;
			} elsif (defined($lastOnline->{$coach}) && defined($lastOnline->{$coach}->{gps})) {
				$gpsepoch = $lastOnline->{$coach}->{gps}->{epoch};
				$lat = $lastOnline->{$coach}->{gps}->{lat};
				$lon = $lastOnline->{$coach}->{gps}->{lon};
			}
			
			my $stoptimeline = '';
			$stoptimeline = strftime("%Y%m%d %H:%M",localtime($stopepoch+$EASTERN_OFFSET*3600)) if (defined($stopepoch));
			my $stationtimeline = '';
			$stationtimeline = strftime("%Y%m%d %H:%M",localtime($stationepoch+$EASTERN_OFFSET*3600)) if (defined($stationepoch));
			
			my ($data1timeline,$data1Status,$data2timeline,$data2Status) = ('','Offline','','Offline');
			if (defined($dataLastStatus->{$coach}) && defined($dataLastStatus->{$coach}->{1}) &&
						  ($dataLastStatus->{$coach}->{1} ne '') && ($dataLastStatus->{$coach}->{1} > 0) )  {
				$data1timeline = strftime("%Y%m%d %H:%M",localtime($dataLastStatus->{$coach}->{1}+$EASTERN_OFFSET*3600));
				$lastOnline->{$coach}->{1} = $dataLastStatus->{$coach}->{1};
			} elsif (defined($lastOnline->{$coach}) && defined($lastOnline->{$coach}->{1}) && 
			                ($lastOnline->{$coach}->{1} ne '') && ($lastOnline->{$coach}->{1} > 0)) {
				$data1timeline = strftime("%Y%m%d %H:%M",localtime($lastOnline->{$coach}->{1}+$EASTERN_OFFSET*3600));
			}
			if (defined($dataLastStatus->{$coach}) && defined($dataLastStatus->{$coach}->{2}) &&
						  ($dataLastStatus->{$coach}->{2} ne '') && ($dataLastStatus->{$coach}->{2} > 0)) {
				$data2timeline = strftime("%Y%m%d %H:%M",localtime($dataLastStatus->{$coach}->{2}+$EASTERN_OFFSET*3600)) ;
				$lastOnline->{$coach}->{2} = $dataLastStatus->{$coach}->{2};
			} elsif (defined($lastOnline->{$coach}) && defined($lastOnline->{$coach}->{2}) &&
								 ($lastOnline->{$coach}->{2} ne '') && ($lastOnline->{$coach}->{2} > 0) ) {
				$data2timeline = strftime("%Y%m%d %H:%M",localtime($lastOnline->{$coach}->{2}+$EASTERN_OFFSET*3600));
			}
			$data1Status = 'Online' if (defined($dataLastStatus->{$coach}) && defined($dataLastStatus->{$coach}->{1}) &&
							 					(($curepoch - $dataLastStatus->{$coach}->{1}) < $DataOfflineWindow) );
			$data2Status = 'Online' if (defined($dataLastStatus->{$coach}) && defined($dataLastStatus->{$coach}->{2}) &&
							 					(($curepoch - $dataLastStatus->{$coach}->{2}) < $DataOfflineWindow) );

			my $statusLine = "$coach,$timeline,$gpstimeline,$gpsStatus,$lat,$lon," .
							"$stoptimeline,$stopname,$stationtimeline,$stationname," .
							"$data1timeline,$data1Status,$data2timeline,$data2Status";
							
			print $outfh "$statusLine\n";
		}
	}	
	close($outfh);
	writeLastOnline($lastOnline);
} else {
	print "Unable to open CurrentStatus.csv\t$!\n";
}

copy("CurrentStatus.csv","$outdir/CurrentStatus.csv" );

1;