#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(cwd);
use Time::Local;
use Getopt::Std;

my $USAGE = "Usage: getClip.pl\n".
                  "\t   -c Coach             \n" .
                  "\t   -d Input dir         \n" .
                  "\t   -D output dir        \n" .
                  "\t   -e end time epoch    \n" .
                  "\t   -E end offset (sec)  \n" .
                  "\t   -f CSV data file     \n" .
                  "\t   -l clip len (sec)    \n" .                  
                  "\t   -m MACs              \n" .
                  "\t   -n Channel [0..3]    \n" .
                  "\t   -s start time epoch  \n" .              
                  "\t   -S start offset (s)  \n" .              
                  "\t   -t targDir           \n" .              
                  "   file1 file2 ...        \n\n" .
            "CSV file {startepoch,endepoch,fname}\n";

sub logMsg {
   my $msg = shift;
   print "$msg\n";
}

sub getCmdLine {
   my ($startEpoch, $endEpoch,$dir,$MACs,$coach,$chan);
   my %options=();
   
   getopts("hc:d:D:e:E:f:l:m:n:s:S:t:", \%options);
   if (defined $options{h})   {
      die $USAGE;
   }
   $startEpoch = $options{s} if defined($options{s});
   $startEpoch = 0 unless defined($startEpoch);
   $endEpoch = $startEpoch + 15 * 60;           # default 15 minutes
   $endEpoch = $options{e} if defined($options{e});
   $endEpoch = $startEpoch + $options{l} if defined($options{l});
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
   my $fStartEpoch = timegm($ss,$mm,$hh,$mday,--$mon,$year) + $start;
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
   my ($fname,$start,$end,$cntr) = @_;
   print "File $fname start $start End $end\n";

   my ($fStartEpoch,$fEndEpoch,$MAC) = parseFname($fname);
   my $ret = `ffmpeg -i $fname 2>&1 | grep "Duration" |cut -d ' ' -f 4 |sed s/,//`;
   my $ffDur = 3600*substr($ret,0,2) + 60*substr($ret,3,2) +
                    substr($ret,6,2) + substr($ret,9,2)/100;
   my $fnDur = $fEndEpoch - $fStartEpoch;
   my $durScale = $ffDur / $fnDur;
   

   my ($SSopt,$TOopt) = ("-ss 0","");
   my $FileOffset = $start -$fStartEpoch;
   my $offset = $durScale * $FileOffset;
   $SSopt = "-ss $offset " if ($offset > 0);       # start of clip is in the file
   $offset = $offset + $durScale*($end - $start);
   $TOopt = "-to $offset" if ($end < $fEndEpoch);  # end of clip is in the file
   my $cntrStr = "";
   $cntrStr = "_" . $cntr . "_" if ( defined($cntr) && ($cntr ne '') );
   my $targName = 'clip_' . $MAC . '_' . $start .'_'. $end . $cntrStr . '.mp4';
   my $cmd = 'ffmpeg -loglevel panic -y ' .
             "-i $fname $SSopt $TOopt -c copy $targName";  
   logMsg "Extracting Scale $ffDur,$fnDur,$durScale $SSopt $TOopt -i $fname into $targName\n$cmd";
   my $cmdRet = `$cmd`;
   
   my $retVal = $targName if (-e $targName);
   return($retVal);
}

sub mvClips {
   my $targDir = shift;
   
   if (defined($targDir)  && (-d $targDir) ) {
      print "Copying files to $$targDir\n";
      foreach my $curFname (@_) {
         my $targName = $targDir . '/' . $curFname;
         `mv -f $curFname $targName` if defined($targName ne $curFname);
      }
   }
}

my ($startEpoch,$endEpoch,$dir,$MACs,$coach,$chan,$options) = getCmdLine();
my $fList = getFileList($dir,$MACs,$coach,$chan,$options);
my $odir = $options->{o} if defined($options->{o});

my $fCnt = scalar @$fList;
logMsg "Searching $fCnt files";
my ($firstClip,$lastClip,@fullFiles,$fullClip);
if (scalar @$fList > 1) {
   logMsg "Looking for $startEpoch to $endEpoch in $fCnt files";  
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
   my $lastFile   = pop(@fullFiles);
   
   $firstClip  = getClip($firstFile,$startEpoch,$endEpoch) if defined($firstFile);
   $lastClip   = getClip($lastFile,$startEpoch,$endEpoch,1)  if defined($lastFile);
 
#   $fullClip      = catMP4($firstClip,$lastClip,@fullFiles);
} elsif (scalar @$fList ) {
   # Process the only file on the list
   my $curFile = shift @$fList;
   my ($fStartEpoch,$fEndEpoch,$MAC) = parseFname($curFile);
   my $ret = `ffmpeg -i $curFile 2>&1 | grep "Duration" |cut -d ' ' -f 4 |sed s/,//`;
   my $ffDur = 3600*substr($ret,0,2) + 60*substr($ret,3,2) +
                    substr($ret,6,2) + substr($ret,9,2)/100;
   my $fnDur = $fEndEpoch - $fStartEpoch;
   my $durScale = $ffDur / $fnDur;
   my $SSopt = "-ss 0";
   $SSopt = "-ss ". int($durScale*$options->{S}) if ( defined($options->{S}) );
   my $start = $fStartEpoch + $durScale*$options->{S} if ( defined($options->{S}) );
   my $fileStart = $fStartEpoch + $options->{S};
   my ($end,$fileEnd);
   if (defined($options->{E})) {
      $end = $durScale*$options->{E};
      $fileEnd = $options->{E};
      $fileEnd -= $options->{S} if defined($options->{S});
   }
   $end = $start + $durScale*$options->{l} if defined($options->{l});
   $fileEnd = $options->{l} if defined($options->{l});
   $fileEnd = int($fileEnd) + 1 unless (int($fileEnd) == $fileEnd);
   my $TOopt = "-to $end";
   my $targName = 'clip_' . $MAC . '_' . $fileStart .'_'. $fileEnd . '.mp4';
   print "ffmpeg Dur: $ffDur  file Dur: $fnDur  scale $durScale\n";
   my $cmd = 'ffmpeg -loglevel panic -y ' .
                "-i $curFile $SSopt $TOopt -c copy $targName";  
   logMsg "Scale $durScale\nExtracting $cmd";
   my $cmdRet = `$cmd`;
   $firstClip = $targName;
   $fullClip = $targName;
} else {
   die $USAGE;
}

my $statLine = "Created $firstClip";
$statLine .= "," . join(',',@fullFiles) if (scalar @fullFiles > 0);
$statLine .= ",$lastClip" if defined($lastClip) && ($lastClip ne '');
logMsg "$statLine\n";

mvClips($options->{t},$firstClip,$lastClip,@fullFiles);
`ls -ltr $options->{t}`;

1;