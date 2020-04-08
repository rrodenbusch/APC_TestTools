#!/usr/bin/perl
use strict;
use warnings;

my $epoch = time();
$epoch -= 7*3600;  # backup 7 hours of gmtime to get 2am eastern
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($epoch);
my $dateStr = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
print "$dateStr\n";

1;
