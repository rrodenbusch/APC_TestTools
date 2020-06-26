#!/usr/bin/perl
use strict;
use warnings;

my $config = `/sbin/ifconfig`;

my @lines = split("\n",$config);
my $lineNum = 1;
my ($dev,$inet,$ether);
foreach my $curLine (@lines) {
   my @flds = split(' ', $curLine);
   if ($lineNum == 1) {
      $dev = $flds[0];
      $dev =~ s/://g;
   }
   $ether = $flds[1] if ($flds[0] eq 'ether');
   $inet = $flds[1] if ($flds[0] eq 'inet');
   $lineNum++;
   if ($curLine eq '' ) {
      $lineNum=1;
      print "$dev,$ether,$inet\n";
      ($dev,$ether,$inet) = ('','','');
   }
}


1;
