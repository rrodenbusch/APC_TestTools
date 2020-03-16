#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use Time::Local;
use Getopt::Std;

sub getCmdLine {
   my ($startEpoch, $endEpoch,$dir,$MACs,$coach,$chan);
   my %options=();

   getopts("hs:e:d:m:D:c:n:", \%options);
   if (defined $options{h})   {
      die "Usage: getClip.pl -f CSV data file -s startepoch -e endepoch -d directory -m MACs -c Coach -n Channel [0..3]   file1 file2 ...\n" .
            "CSV file {startepoch,endepoch,fname}\n";
   }
   $startEpoch = $options{s} if defined($options{s});
   $startEpoch = 0 unless defined($startEpoch);
   $endEpoch = $startEpoch + 15 * 60;           # default 15 minutes
   $endEpoch = $options{e} if defined($options{e});
   $endEpoch = $startEpoch + $options{D} if defined($options{D});
   $dir = cwd;
   $dir = $options{d} if defined($options{d});
   $MACs = $options{m} if defined($options{m});
   $coach = $options{c} if defined($options{c});
   $chan = $options{n} if defined($options{n});
   
   return($startEpoch,$endEpoch,$dir,$MACs,$coach,$chan,\%options);
}

sub getFtimes{
   ##   xxxxxx_YYYYMMDDhhmmss-aaaaaa-bbbbbb.mp4
   ##   xxxxxx  last 6 of MAC on video feed
   ##   YYYYYMMDDhhmmss  date time
   ##   aaaaaaa, bbbbbbb start and end offset (secs) of the file vs datetime
   my $curFile = shift;
   my ($year,$mon,$mday,$hh,$mm,$ss,$start) = 
              (substr($curFile,7,4),substr($curFile,11,2),substr($curFile,13,2),
               substr($curFile,15,2),substr($curFile,17,2),substr($curFile,19,2),substr($curFile,22,5));
   print "Checking $curFile $ss $mm $hh $mday $mon $year $start\n";
   my $fStartEpoch = timelocal($ss,$mm,$hh,$mday,--$mon,$year) + $start;
   my $fEndEpoch   = (stat $curFile)[9];
   return($fStartEpoch,$fEndEpoch);
}

sub getFileList{
   my ($dir,$MACs,$coach,$chan,$options) = @_;
   my ($fList,@files);
   
   die "Bad working directory\n" unless ( ($dir eq cwd()) || (chdir($dir)) );
   if (scalar @ARGV > 0) { # No command line files
      $fList = \@ARGV;
   } else {
      my @files;
      @files = glob('*.mp4') unless (defined($MACs));
      @files = glob("$MACs".'_*') if (defined($MACs));
      $fList = \@files;
   }
   return($fList);   
}


my ($startEpoch,$endEpoch,$dir,$MACs,$coach,$chan,$options) = getCmdLine();
my $fList = getFileList($dir,$MACs,$coach,$chan,$options);

my $fCnt = scalar @$fList;
print "Looking for $startEpoch to $endEpoch in $fCnt files mac $MACs\n";

my ($firstFile,$lastFile,@fullFiles);
foreach my $curFile (@$fList) {
   my ($fStartEpoch,$fEndEpoch) = getFtimes($curFile);
   $firstFile   = $curFile if ( ($startEpoch >= $fStartEpoch) && ($startEpoch <= $fEndEpoch) ); 
   push(@fullFiles,$curFile) if ( defined($firstFile) && ($firstFile eq $curFile));
   $lastFile    = $curFile if ( ($endEpoch >= $fStartEpoch) && ($endEpoch <= $fEndEpoch) );
   push(@fullFiles,$curFile) if ( defined($lastFile) && ($lastFile eq $curFile));
   if ( !( defined($firstFile) && ($firstFile eq $curFile) )   && 
        !( defined($lastFile)  && ($lastFile eq $curFile) ) ){
      push(@fullFiles,$curFile) if ( ($fStartEpoch >= $startEpoch) && ($fEndEpoch <= $endEpoch) );        
   }
}

my $targName;
my $ffmpeg = 'ffmpeg -loglevel panic -acodec copy -vcodec copy';
foreach my $curFile (@fullFiles) {
   if  ( ($curFile eq $firstFile) && ($curFile eq $lastFile) )  {
      my ($fStartEpoch,$fEndEpoch) = getFtimes($curFile);
      my $clipStart = $startEpoch - $fStartEpoch;
      my $clipEnd = $clipStart + ($endEpoch - $startEpoch);
      $targName = 'clip_' . $startEpoch .'_'. $endEpoch . '.mp4';
      print "Extracting from $clipStart for $clipEnd from $curFile into $targName\n";
      
      my $cmdRet = `$ffmpeg -i $curFile -ss $clipStart -to $clipEnd $targName`;
   }
}

my $ret = `ls -ltr $targName`;
print $ret;

1;