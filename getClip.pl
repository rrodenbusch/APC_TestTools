#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use Time::Local;


use Getopt::Std;
# declare the perl command line flags/options we want to allow
my %options=();
getopts("hs:e:d:m:D:", \%options);
if (defined $options{h})   {
   print "Usage: getClip.pl -f CSV data file -s startepoch -e endepoch -d directory -m MACs -c Coach -n Channel [0..3]   file1 file2 ...\n" .
         "CSV file {startepoch,endepoch,fname}\n";
   exit;
}

my ($startEpoch, $endEpoch,$dirName,$MACs,$coach,$chan,$dir);
$startEpoch = $options{s} if defined($options{s});
$startEpoch = 0 unless defined($startEpoch);
$endEpoch = $startEpoch + 15 * 60;           # default 15 minutes
$endEpoch = $options{e} if defined($options{e});
$endEpoch = $startEpoch + $options{D} if defined($options{D});
my $curDir = cwd;
$dir = $curDir;
$dir = $options{d} if defined($options{d});
$MACs = $options{m} if defined($options{m});

die "Bad working directory\n" unless ( ($dir eq $curDir) || (chdir($dir)) );
my $fList;
if (scalar @ARGV > 0) { # No command line files
   $fList = \@ARGV;
} else {
   my @files;
   @files = glob('*.mp4') unless (defined($MACs));
   @files = glob("$MACs".'_*') if (defined($MACs));
   $fList = \@files;
}
my $fCnt = scalar @$fList;
print "Looking for $startEpoch to $endEpoch in $fCnt files mac $MACs\n";

my ($firstFile,$lastFile,@fullFiles);
foreach my $curFile (@$fList) {
   my $dateStr = substr($curFile,0,-4);
   $dateStr = substr($dateStr,7);
   my @parts = split('-',$dateStr);
   my $dayStr =  substr($parts[0],0,8);
   my $tofday = substr($parts[0],8,6);
   my $start = $parts[1];
   my $end = $parts[2];
   my ($year,$mon,$mday) = (substr($dayStr,0,4),substr($dayStr,4,2),substr($dayStr,6,2));
   my ($hh,$mm,$ss) = (substr($tofday,0,2),substr($tofday,2,2),substr($tofday,4,2));
   $mon--;
   print "Checking $curFile $ss $mm $hh $mday $mon $year\n";
   my $fEpoch = timelocal($ss,$mm,$hh,$mday,$mon,$year);
   my $fStartEpoch = $fEpoch + $start;
   my $fEndEpoch = $fEpoch + $end;

   my $firstFile = $curFile if ( ($startEpoch >= $fStartEpoch) && ($startEpoch <= $fEndEpoch) );
   
   my $lastFile  = $curFile if ( ($endEpoch >= $fStartEpoch) && ($endEpoch <= $fEndEpoch) );
   my (@fullFiles);
   push(@fullFiles,$curFile) if ( ($fStartEpoch >= $startEpoch) && ($fEndEpoch <= $endEpoch) );
}
   
   my $lineStr = "$firstFile ";
   $lineStr .=  join(' ',@fullFiles) if (scalar @fullFiles > 0);
   $lineStr .= " $lastFile";
   
   print "$lineStr\n";


1;