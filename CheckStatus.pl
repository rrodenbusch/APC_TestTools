#!/usr/bin/perl
use lib "$ENV{HOME}/bin6";
use strict;
use warnings;
use ConsistStatus;
use POSIX qw(strftime);
use Time::Local;
use JSON;

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

#
#   MAIN
#
# Get the directory and current date and previous date for the GPS extraction
#   The schedule determines the window for the entire report
#
#

my $srcdir = "$ENV{HOME}/bin6";
my $fleetDefn = ConsistStatus->new($srcdir);
my $coachNames = $fleetDefn->coachNames();
my $curCoach = $ARGV[0];
my $ua = $fleetDefn->NVFbrowser();

my $gpsLastStatus = queryLastGPS($fleetDefn);
my $dataLastStatus = queryLastData($fleetDefn,$ua);

my @coaches;
if (defined($curCoach) ) {
	push(@coaches,$curCoach);
} else {
	@coaches = sort @{$coachNames};
}
my $curepoch = time();
print "\n";
foreach $curCoach (@coaches) {
	my ($lat,$lon) = ('','');
	my ($gpstime,$data1,$data2) = ('OFFLINE ','OFFLINE ','OFFLINE ');
	$lat = $gpsLastStatus->{$curCoach}->{lat} if defined($gpsLastStatus->{$curCoach}->{lat});
	$lat = $gpsLastStatus->{$curCoach}->{lon} if defined($gpsLastStatus->{$curCoach}->{lon});
	if (defined($gpsLastStatus->{$curCoach}->{epoch})) {
		if ( ($curepoch - $gpsLastStatus->{$curCoach}->{epoch}) < 300) {
			$gpstime = "ONLINE  ";
		}
		$gpstime .= strftime("%Y%m%d %H:%M:%S",localtime($gpsLastStatus->{$curCoach}->{epoch}));
	} else {
		$gpstime .= "\t\t";
	}
	if (defined($dataLastStatus->{$curCoach}->{1})) {
		if ( ($curepoch - $dataLastStatus->{$curCoach}->{1}) < 300) {
			$data1 = "ONLINE  ";
		}
		$data1 .= strftime("%Y%m%d %H:%M:%S",localtime($dataLastStatus->{$curCoach}->{1}));
		$data1 .= "\t";
	} else {
		$data1 .= "\t\t\t";
	}
	if (defined($dataLastStatus->{$curCoach}->{2})) {
		if ( ($curepoch - $dataLastStatus->{$curCoach}->{2}) < 300) {
			$data2 = "ONLINE  ";
		}
		$data2 .= strftime("%Y%m%d %H:%M:%S",localtime($dataLastStatus->{$curCoach}->{2}));
	} else {
		$data2 .= "\t\t\t";
	}
	print "$curCoach\tGPS:$gpstime\tEND1: $data1\tEND2 $data2\n";
}

1;