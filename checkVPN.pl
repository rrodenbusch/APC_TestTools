#!/usr/bin/perl
use strict;
use warnings;
use Net::Ping;

my $targCoach = $ARGV[0];
my $FleetFile = "$ENV{HOME}/bin6/FleetDefinition.csv";
my $ipFile = "$ENV{HOME}/git/APC_TestTools/ipp.txt";
warn "Usage:  checkVPN.pl  coach#\n" unless defined($targCoach);

my $p = Net::Ping->new();
if ($p->ping("10.50.0.1")) {
	print "\nVPN Online\n";
	exit 1 unless defined($targCoach);
} else {
	print "\nVPN OFFLINE\n";
	exit 0;
}
print "   Checking coach $targCoach\t";
open(my $fh, "$FleetFile") or die "Unable to open $FleetFile\n";
my $header = <$fh>;
$header =~ s/\R//g;
my @names = split(',',$header);
shift(@names);
while (my $line = <$fh>) {
	$line =~ s/\R//g;
	my @fields = split(',',$line);
	my @alive;
	my $coach = shift(@fields);
	if ($coach eq $targCoach) {
		my $cnt = scalar(@fields);
		$cnt = scalar(@names) if (scalar(@names) > $cnt);
		print "\t$names[0]:\t$fields[0]\n";
		for (my $i =0; $i < $cnt; $i++ ) {
			my @parts = split(' ',$names[$i]);
			my $last = pop(@parts);
			if ($last eq 'VPN') {
				if ( defined($fields[$i]) ) {
					$names[$i] = "OtherIP" unless defined($names[$i]);
					print "\t$names[$i]:\t$fields[$i]";
					my $ip = $fields[$i];
					$ip =~ s/ //g;
					if ( ($ip ne '') ) {
						if ($p->ping($fields[$i]) ) {
							print "\tALIVE\n";
						} else {
							print "\tOffline\n";
						}									
					} else {
						print "\n";
					}
				} else {
					print "\t$names[$i]:\tUndef\n";
				}
			} elsif ( ($last eq 'MAC') && ($parts[0] eq 'CP') ) {
				my ($p1,$p2,$p3) = (substr($fields[$i],6,2),substr($fields[$i],8,2),substr($fields[$i],10,2));
				my $gpsID = hex($p1) . hex($p2) . hex($p3);
				print "\tGPS ID\t$gpsID\n";
			} 
		}
	}
}
close($fh);

1;
