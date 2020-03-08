#!/bin/perl
use strict;
use warnings;


my $hostname = `hostname`;
$hostname =~ s/\R//g;

my $lines = `grep $hostname /etc/hosts`;
my @fields = split('\n',$lines);
my $hostOK = 0;

while ( !$hostOK && (scalar @fields > 0)) {
   my $curLine = shift(@fields);
   my ($ip,$name) = split(" ", $curLine);
   $hostOK = (($ip eq '127.0.0.1') && ($name eq $hostname));
}

if (!$hostOK) {
   my $cmd = "sudo echo '127.0.0.1  $hostname' >> /etc/hosts";  
   `$cmd`;
}

1;