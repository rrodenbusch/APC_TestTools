#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use Time::Local;
use Getopt::Std;


sub logMsg {
   my $msg = shift;
   print "$msg\n";
}

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

sub parseFname {
   ##   xxxxxx_YYYYMMDDhhmmss-aaaaaa-bbbbbb.mp4
   ##   xxxxxx  last 6 of MAC on video feed
   ##   YYYYYMMDDhhmmss  date time
   ##   aaaaaaa, bbbbbbb start and end offset (secs) of the file vs datetime
   my $curFile = shift;
   my ($MAC, $year,$mon,$mday,$hh,$mm,$ss,$start) = 
              (substr($curFile,0,6),substr($curFile,7,4),substr($curFile,11,2),substr($curFile,13,2),
               substr($curFile,15,2),substr($curFile,17,2),substr($curFile,19,2),substr($curFile,22,5));
   logMsg "Checking $curFile $ss $mm $hh $mday $mon $year $start";
   my $fStartEpoch = timelocal($ss,$mm,$hh,$mday,--$mon,$year) + $start;
   my $fEndEpoch   = (stat $curFile)[9];
   return($fStartEpoch,$fEndEpoch,$MAC);
}

sub getFileList{
   my ($dir,$MACs,$coach,$chan,$options) = @_;
   my ($fList,@files);
   
   if ( ($dir ne cwd()) && (!chdir($dir)) ) {
      my $msg = "Bad working directory, $!";
      logMsg $msg;
      die $msg;   
   }
   
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

sub catMP4 {
   my $firstClip = shift;
   my $lastClip  = shift;
   my @wholeFiles = @_;

   my $clipName = $firstClip;
   
   if ( (scalar @wholeFiles > 0) || (defined($lastClip)) ) {
      ### Put them together and then cleanup
      logMsg("Concatenating files");
   }
   
   return($firstClip);
}

sub getClip {
   my ($fname,$start,$end) = @_;
   my $ffmpeg = 'ffmpeg -loglevel warning -acodec copy -vcodec copy';

   my ($fStartEpoch,$fEndEpoch,$MAC) = parseFname($fname);

   my ($SSopt,$TOopt) = ("-ss 0","");
   my $offset = $start -$fStartEpoch;
   $SSopt = "-ss $offset " if ($offset > 0);       # start of clip is in the file
   $offset = $start - $end;
   $TOopt = "-to $offset" if ($end < $fEndEpoch);  # end of clip is in the file
   
   my $targName = 'clip_' . $MAC . '_' . $start .'_'. $end . '.mp4';
   my $cmd = "$ffmpeg -i $fname $SSopt $TOopt $targName";  
   logMsg "Extracting $SSopt $TOopt -i $fname into $targName";
   logMsg "cmd : $cmd";
   my $cmdRet = `$cmd`;
   
   my $retVal = $targName if (-e $targName);
   return($retVal);
}

my ($startEpoch,$endEpoch,$dir,$MACs,$coach,$chan,$options) = getCmdLine();
my $fList = getFileList($dir,$MACs,$coach,$chan,$options);

my $fCnt = scalar @$fList;
logMsg "Looking for $startEpoch to $endEpoch in $fCnt files";

my @fullFiles;
foreach my $curFile (@$fList) {
   my ($firstFile,$lastFile,$wholeFile) = ('','','');
   my ($fStartEpoch,$fEndEpoch) = parseFname($curFile);

   $firstFile   = $curFile if ( ($startEpoch >= $fStartEpoch) && ($startEpoch <= $fEndEpoch) );   
   $lastFile    = $curFile if ( ($endEpoch >= $fStartEpoch)   && ($endEpoch <= $fEndEpoch) && ($firstFile eq '') );
   $wholeFile   = $curFile if ( ($startEpoch >= $fStartEpoch) && ($endEpoch <= $fEndEpoch) && ($firstFile eq '') && ($lastFile eq ''));

   push(@fullFiles,$curFile) if ( defined($firstFile) && ($firstFile eq $curFile));
   push(@fullFiles,$lastFile) if ( $lastFile ne '' );

   if ( !( defined($firstFile) && ($firstFile eq $curFile) )   && 
        !( defined($lastFile)  && ($lastFile eq $curFile) ) ){
      push(@fullFiles,$curFile) if ( ($fStartEpoch >= $startEpoch) && ($fEndEpoch <= $endEpoch) );        
   }
}

my $firstFile  = shift(@fullFiles);
my $firstClip  = getClip($firstFile,$startEpoch,$endEpoch);

my $lastFile   = pop(@fullFiles);
my $lastClip   = getClip($lastFile,$startEpoch,$endEpoch) if defined($lastFile);

my $fullClip   = catMP4($firstClip,$lastClip,@fullFiles);
logMsg `ls -ltr $fullClip`;

1;