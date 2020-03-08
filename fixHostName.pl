#!/usr/bin/perl
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
   print "Hostname not found, Fixing\n";
   if (open (my $fh, ">$ENV{HOME}/fixhost.sh")) {
      print $fh "echo '127.0.0.1      $hostname' >>/etc/hosts\n";
      close $fh;
      `chmod +x $ENV{HOME}/fixhost.sh`;
      `sudo $ENV{HOME}/fixhost.sh`;
      $lines = `grep $hostname /etc/hosts`;
      print "Found the following:\n$lines\n";
   } else {
      print "Unable to open $ENV{HOST}/fixhost.sh\n$!";
   }
}

1;