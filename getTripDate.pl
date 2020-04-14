#!/usr/bin/perl
use strict;
use warnings;

my $epoch = time();
$epoch -= 8*3600;  # backup 7 hours of gmtime to get 3am eastern (1 hr after reports shift to next day)
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($epoch);
my $dateStr = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
print "$dateStr\n";

1;
