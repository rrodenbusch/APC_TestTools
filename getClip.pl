#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);


use Getopt::Std;
# declare the perl command line flags/options we want to allow
my %options=();
getopts("hs:e:d:m", \%options);
if (defined $options{h})   {
   print "Usage: getClip.pl -f CSV data file -s startepoch -e endepoch -d directory -m MACs -c Coach -n Channel [0..3]   file1 file2 ...\n" .
         "CSV file {startepoch,endepoch,fname}\n";
   exit;
}

my ($startEpoch, $endEpoch,$dirName,$MACs,$coach,$chan,$dir);
$startEpoch = $options{s} if defined($options{s});
$endEpoch = $startEpoch + 15 * 60;           # default 15 minutes
$endEpoch = $options{e} if defined($options{e});
my $curDir = cwd;
$dir = $curDir;
$dir = $options{d} if defined($options{d});
$MACs = $options{m} if defined($options{m});

die "Bad working directory\n" unless ( ($dir eq $curDir) || (chdir($dir)) );
my $fList;
if (@ARGV == 0) { # No command line files
   $fList = \@ARGV;
} else {
   my @files;
   @files = glob('*') unless (defined($MACs));
   @files = glob($MACs) if (defined($MACs));
   $fList = \@files;
}
my $fCnt = scalar @$fList;
print "Looking for $startEpoch to $endEpoch in $fCnt files\n" . join (",",@$fList) . "\n";


1;