#!/usr/bin/perl
use strict;
use warnings;
use Net::Ping;

my $targCoach = $ARGV[0];
warn "Usage:  checkVPN.pl  coach#\n" unless defined($targCoach);

my $p = Net::Ping->new();
if ($p->ping("10.50.0.1")) {
	print "\nVPN Online\n";
	exit 1 unless defined($targCoach);
} else {
	print "\nVPN OFFLINE\n";
	exit 0;
}
print "   Checking coach $targCoach\n";
open(my $fh, "/home/richard/git/APC_TestTools/vpnDefn.ini") or die "Unable to open vpnDefn.ini\n";
my $header = <$fh>;
$header =~ s/\R//g;
$header =~ s/ //g;
my @names = split(',',$header);
shift(@names);
while (my $line = <$fh>) {
	$line =~ s/\R//g;
	$line =~ s/ //g;
	my @fields = split(',',$line);
	my @alive;
	my $coach = shift(@fields);
	if ($coach eq $targCoach) {
		my $cnt = scalar(@fields);
		$cnt = scalar(@names) if (scalar(@names) > $cnt);
		for (my $i =0; $i < $cnt; $i++ ) {
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
		}
	}
}
close($fh);

1;
