#!/usr/bin/perl
use strict;
use warnings;
use Net::Ping;

my $targCoach = $ARGV[0];
die "checkVPN.pl  coach#\n" unless defined($targCoach);
print "Checking coach $targCoach\n";
open(my $fh, "vpnDefn.ini") or die "Unable to open vpnDefn.ini\n";
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
		my $p = Net::Ping->new();
		for (my $i =0; $i < scalar(@names); $i++ ) {
			if ( defined($fields[$i]) ) {
				print "\t$names[$i]:\t$fields[$i]";
				if ($p->ping($fields[$i]) ) {
					print "\tALIVE\n";
				} else {
					print "\tOffline\n";
				}				
			} else {
				print "\t$names[$i]:\tUndef\n";
			}
		}
	}
}
close($fh);

1;
